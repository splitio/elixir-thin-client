defmodule Stplit.RPC.ResponseParser do
  @moduledoc """
  Parses the response from the Split.io API.
  """
  use Split.RPC.Opcodes

  alias Split.RPC.Fallback
  alias Split.RPC.Message
  alias Split.Telemetry
  alias Split.Treatment

  @type t :: {:ok, map()} | {:error, term()}

  def parse_response({:ok, %{"s" => 1, "p" => treatment}}, %Message{o: opcode, a: args})
      when opcode in [@get_treatment_opcode, @get_treatment_with_config_opcode] do
    treatment = Treatment.build_from_daemon_response(treatment)
    user_key = Enum.at(args, 0)
    feature_name = Enum.at(args, 2)

    Telemetry.send_impression(user_key, feature_name, treatment)
    {:ok, treatment}
  end

  def parse_response({:ok, %{"s" => 1, "p" => %{"r" => treatments}}}, %Message{o: opcode, a: args})
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

  def parse_response({:ok, %{"s" => 1, "p" => payload}}, %Message{o: @split_opcode}) do
    {:ok, parse_split(payload)}
  end

  def parse_response({:ok, %{"s" => 1, "p" => %{"n" => split_names}}}, %Message{
        o: @split_names_opcode
      }) do
    {:ok, %{split_names: split_names}}
  end

  def parse_response({:ok, %{"s" => 1, "p" => %{"s" => splits}}}, %Message{o: @splits_opcode}) do
    splits =
      Enum.reduce(splits, [], fn split, acc ->
        [parse_split(split) | acc]
      end)

    {:ok, splits}
  end

  def parse_response({:ok, %{"s" => 1, "p" => %{"s" => true}}}, %Message{o: @track_opcode}) do
    :ok
  end

  def parse_response(response, request) do
    if :persistent_term.get(:splitd_fallback_enabled) do
      Fallback.fallback(request)
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
