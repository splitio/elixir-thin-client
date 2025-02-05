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
  alias Split.SplitView

  @type splitd_response :: {:ok, map()} | {:error, term()}

  @doc """
  Parses the response from the Splitd RPC calls.
  """
  @spec parse_response(response :: splitd_response(), request :: Message.t(), [
          {:span_context, reference()} | {:span_context, nil}
        ]) :: map() | list() | Treatment.t() | Split.t() | boolean() | nil

  def parse_response(response, original_request, opts \\ [])

  def parse_response(
        {:ok, %{"s" => @status_ok, "p" => treatment_data}},
        %Message{
          o: opcode,
          a: args
        },
        _opts
      )
      when opcode in [@get_treatment_opcode, @get_treatment_with_config_opcode] do
    treatment = Treatment.build_from_daemon_response(treatment_data)
    user_key = Enum.at(args, 0)
    feature_name = Enum.at(args, 2)

    Telemetry.send_impression(user_key, feature_name, treatment)
    treatment
  end

  def parse_response(
        {:ok, %{"s" => @status_ok, "p" => %{"r" => treatments}}},
        %Message{
          o: opcode,
          a: args
        },
        _opts
      )
      when opcode in [@get_treatments_opcode, @get_treatments_with_config_opcode] do
    treatments = Enum.map(treatments, &Treatment.build_from_daemon_response/1)
    user_key = Enum.at(args, 0)
    feature_names = Enum.at(args, 2)

    mapped_treatments =
      Enum.zip_reduce(feature_names, treatments, %{}, fn feature_name, treatment, acc ->
        Telemetry.send_impression(user_key, feature_name, treatment)
        Map.put(acc, feature_name, treatment)
      end)

    mapped_treatments
  end

  def parse_response(
        {:ok, %{"s" => @status_ok, "p" => payload}},
        %Message{o: @split_opcode},
        _opts
      ) do
    parse_split(payload)
  end

  def parse_response(
        {:ok, %{"s" => @status_ok, "p" => %{"n" => split_names}}},
        %Message{
          o: @split_names_opcode
        },
        _opts
      ) do
    split_names
  end

  def parse_response(
        {:ok, %{"s" => @status_ok, "p" => %{"s" => splits}}},
        %Message{
          o: @splits_opcode
        },
        _opts
      ) do
    splits =
      Enum.reduce(splits, [], fn split, acc ->
        [parse_split(split) | acc]
      end)

    splits
  end

  def parse_response(
        {:ok, %{"s" => @status_ok, "p" => %{"s" => tracked?}}},
        %Message{
          o: @track_opcode
        },
        _opts
      ) do
    if tracked? do
      true
    else
      false
    end
  end

  def parse_response(
        {:ok, %{"s" => @status_error} = raw_response},
        %Message{} = message,
        opts
      ) do
    Logger.error("Error response received from Splitd",
      request: inspect(message),
      response: inspect(raw_response)
    )

    fallback(message, opts)
  end

  def parse_response({:ok, raw_response}, %Message{} = message, opts) do
    Logger.error("Unable to parse Splitd response",
      request: inspect(message),
      response: inspect(raw_response)
    )

    fallback(message, opts)
  end

  def parse_response({:error, reason}, request, opts) do
    Logger.error("Error while communicating with Splitd",
      request: inspect(request),
      reason: inspect(reason)
    )

    fallback(request, opts)
  end

  defp fallback(original_request, opts) do
    fallback_response = Fallback.fallback(original_request)

    if Keyword.has_key?(opts, :span_context) do
      Telemetry.span_event([:rpc, :fallback], opts[:span_context], %{
        response: fallback_response
      })
    end

    fallback_response
  end

  defp parse_split(payload) do
    %SplitView{
      name: Map.get(payload, "n", nil),
      traffic_type: payload["t"],
      killed: payload["k"],
      treatments: payload["s"],
      change_number: payload["c"],
      configs: payload["f"],
      default_treatment: payload["d"],
      sets: payload["e"],
      impressions_disabled: payload["i"] || false
    }
  end
end
