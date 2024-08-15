defmodule Split.RPC.ResponseParser do
  @moduledoc """
  Contains the functions to parse the response from the Splitd RPC calls.
  """
  require Logger
  use Split.RPC.Opcodes

  alias Split.RPC.Fallback
  alias Split.RPC.Message
  alias Split.Telemetry
  alias Split.Treatment

  @status_ok 0x01
  @status_error 0x10

  @type splitd_response :: {:ok, map()} | {:error, term()}

  @doc """
  Parses the response from the Splitd RPC calls.
  """
  @spec parse_response(response :: splitd_response(), request :: Message.t()) ::
          :ok
          | {:ok, map() | list() | Treatment.t() | Split.t() | nil}
          | {:error, term()}
          | :error
  def parse_response({:ok, %{"s" => @status_ok, "p" => treatment_data}}, %Message{
        o: opcode,
        a: args
      })
      when opcode in [@get_treatment_opcode, @get_treatment_with_config_opcode] do
    treatment = Treatment.build_from_daemon_response(treatment_data)
    user_key = Enum.at(args, 0)
    feature_name = Enum.at(args, 2)

    Telemetry.send_impression(user_key, feature_name, treatment)
    {:ok, treatment}
  end

  def parse_response({:ok, %{"s" => @status_ok, "p" => %{"r" => treatments}}}, %Message{
        o: opcode,
        a: args
      })
      when opcode in [@get_treatments_opcode, @get_treatments_with_config_opcode] do
    treatments = Enum.map(treatments, &Treatment.build_from_daemon_response/1)
    user_key = Enum.at(args, 0)
    feature_names = Enum.at(args, 2)

    mapped_treatments =
      Enum.zip_reduce(feature_names, treatments, %{}, fn feature_name, treatment, acc ->
        Telemetry.send_impression(user_key, feature_name, treatment)
        Map.put(acc, feature_name, treatment)
      end)

    {:ok, mapped_treatments}
  end

  def parse_response({:ok, %{"s" => @status_ok, "p" => payload}}, %Message{o: @split_opcode}) do
    {:ok, parse_split(payload)}
  end

  def parse_response({:ok, %{"s" => @status_ok, "p" => %{"n" => split_names}}}, %Message{
        o: @split_names_opcode
      }) do
    {:ok, %{split_names: split_names}}
  end

  def parse_response({:ok, %{"s" => @status_ok, "p" => %{"s" => splits}}}, %Message{
        o: @splits_opcode
      }) do
    splits =
      Enum.reduce(splits, [], fn split, acc ->
        [parse_split(split) | acc]
      end)

    {:ok, splits}
  end

  def parse_response({:ok, %{"s" => @status_ok, "p" => %{"s" => tracked?}}}, %Message{
        o: @track_opcode
      }) do
    if tracked? do
      :ok
    else
      :error
    end
  end

  def parse_response({:ok, %{"s" => @status_error} = raw_response}, %Message{} = message) do
    Logger.error("Error response received from Splitd",
      request: inspect(message),
      response: inspect(raw_response)
    )

    maybe_fallback({:error, :splitd_internal_error}, message)
  end

  def parse_response({:ok, raw_response}, %Message{} = message) do
    Logger.error("Unable to parse Splitd response",
      request: inspect(message),
      response: inspect(raw_response)
    )

    maybe_fallback({:error, :splitd_parse_error}, message)
  end

  def parse_response({:error, reason}, request) do
    Logger.error("Error while communicating with Splitd",
      request: inspect(request),
      reason: inspect(reason)
    )

    maybe_fallback({:error, reason}, request)
  end

  defp maybe_fallback(response, original_request) do
    if :persistent_term.get(:splitd_fallback_enabled) do
      Fallback.fallback(original_request)
    else
      response
    end
  end

  defp parse_split(payload) do
    %Split{
      name: Map.get(payload, "n", nil),
      traffic_type: payload["t"],
      killed: payload["k"],
      treatments: payload["s"],
      change_number: payload["c"],
      configurations: payload["f"],
      default_treatment: payload["d"],
      flag_sets: payload["e"]
    }
  end
end
