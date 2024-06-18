defmodule Split do
  @moduledoc """
  Documentation for `Split`.
  """
  alias Split.Sockets.Pool
  alias Split.Telemetry
  alias Split.Treatment

  @type t :: %Split{
          name: String.t(),
          traffic_type: String.t(),
          killed: boolean(),
          treatments: [String.t()],
          change_number: integer(),
          configurations: map(),
          default_treatment: String.t(),
          flag_sets: [String.t()]
        }

  defstruct [
    :name,
    :traffic_type,
    :killed,
    :treatments,
    :change_number,
    :configurations,
    :default_treatment,
    :flag_sets
  ]

  @spec get_treatment(String.t(), String.t(), String.t() | nil, map() | nil) ::
          {:ok, Treatment.t()} | {:error, map()}
  def get_treatment(user_key, feature_name, bucketing_key \\ nil, attributes \\ %{}) do
    user_key
    |> Split.RPCs.GetTreatment.build(feature_name, bucketing_key, attributes)
    |> Pool.send_message()
    |> Split.RPCs.GetTreatment.parse_response()
    |> case do
      {:ok, treatment} ->
        Telemetry.send_impression(user_key, feature_name, treatment)
        {:ok, treatment}

      {:error, response} ->
        {:error, response}
    end
  end

  @spec get_treatment_with_config(String.t(), String.t(), String.t() | nil, map() | nil) ::
          {:ok, map()} | {:error, map()}
  def get_treatment_with_config(user_key, feature_name, bucketing_key \\ nil, attributes \\ %{}) do
    user_key
    |> Split.RPCs.GetTreatmentWithConfig.build(feature_name, bucketing_key, attributes)
    |> Pool.send_message()
    |> Split.RPCs.GetTreatmentWithConfig.parse_response()
  end

  @spec get_treatments(String.t(), [String.t()], String.t() | nil, map() | nil) ::
          {:ok, map()} | {:error, map()}
  def get_treatments(user_key, feature_names, bucketing_key \\ nil, attributes \\ %{}) do
    user_key
    |> Split.RPCs.GetTreatments.build(feature_names, bucketing_key, attributes)
    |> Pool.send_message()
    |> Split.RPCs.GetTreatments.parse_response(feature_names)
  end

  @spec get_treatments_with_config(String.t(), [String.t()], String.t() | nil, map() | nil) ::
          {:ok, map()} | {:error, map()}
  def get_treatments_with_config(user_key, feature_names, bucketing_key \\ nil, attributes \\ %{}) do
    user_key
    |> Split.RPCs.GetTreatmentsWithConfig.build(feature_names, bucketing_key, attributes)
    |> Pool.send_message()
    |> Split.RPCs.GetTreatmentsWithConfig.parse_response(feature_names)
  end

  @spec get_treatments_with_config(String.t(), [String.t()], String.t() | nil, map() | nil) ::
          {:ok, map()} | {:error, map()}
  def track(user_key, traffic_type, event_type, value \\ nil, properties \\ %{}) do
    user_key
    |> Split.RPCs.Track.build(traffic_type, event_type, value, properties)
    |> Pool.send_message()
    |> Split.RPCs.Track.parse_response()
  end

  def split_names do
    Split.RPCs.SplitNames.build()
    |> Pool.send_message()
    |> Split.RPCs.SplitNames.parse_response()
  end

  @spec split(String.t()) :: {:ok, Split.t()} | {:error, map()}
  def split(name) do
    name
    |> Split.RPCs.Split.build()
    |> Pool.send_message()
    |> Split.RPCs.Split.parse_response()
  end

  @spec splits() :: {:ok, [Split.t()]} | {:error, map()}
  def splits do
    Split.RPCs.Splits.build()
    |> Pool.send_message()
    |> Split.RPCs.Splits.parse_response()
  end
end
