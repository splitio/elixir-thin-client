defmodule Split do
  @moduledoc """
  Documentation for `Split`.

  ## Telemetry support

  """
  alias Split.Sockets.Pool
  alias Split.Treatment
  alias Split.RPC

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
    RPC.execute_treatment_rpc(
      Split.RPC.GetTreatment,
      user_key: user_key,
      feature_name: feature_name,
      bucketing_key: bucketing_key,
      attributes: attributes
    )
  end

  @spec get_treatment_with_config(String.t(), String.t(), String.t() | nil, map() | nil) ::
          {:ok, map()} | {:error, map()}
  def get_treatment_with_config(user_key, feature_name, bucketing_key \\ nil, attributes \\ %{}) do
    RPC.execute_treatment_rpc(
      Split.RPC.GetTreatmentWithConfig,
      user_key: user_key,
      feature_name: feature_name,
      bucketing_key: bucketing_key,
      attributes: attributes
    )
  end

  @spec get_treatments(String.t(), [String.t()], String.t() | nil, map() | nil) ::
          {:ok, map()} | {:error, map()}
  def get_treatments(user_key, feature_names, bucketing_key \\ nil, attributes \\ %{}) do
    RPC.execute_treatment_rpc(
      Split.RPC.GetTreatments,
      user_key: user_key,
      feature_names: feature_names,
      bucketing_key: bucketing_key,
      attributes: attributes
    )
  end

  @spec get_treatments_with_config(String.t(), [String.t()], String.t() | nil, map() | nil) ::
          {:ok, map()} | {:error, map()}
  def get_treatments_with_config(user_key, feature_names, bucketing_key \\ nil, attributes \\ %{}) do
    RPC.execute_treatment_rpc(
      Split.RPC.GetTreatmentsWithConfig,
      user_key: user_key,
      feature_names: feature_names,
      bucketing_key: bucketing_key,
      attributes: attributes
    )
  end

  @spec get_treatments_with_config(String.t(), [String.t()], String.t() | nil, map() | nil) ::
          {:ok, map()} | {:error, map()}
  def track(user_key, traffic_type, event_type, value \\ nil, properties \\ %{}) do
    user_key
    |> Split.RPC.Track.build(traffic_type, event_type, value, properties)
    |> Pool.send_message()
    |> Split.RPC.Track.parse_response()
  end

  def split_names do
    Split.RPC.SplitNames.build()
    |> Pool.send_message()
    |> Split.RPC.SplitNames.parse_response()
  end

  @spec split(String.t()) :: {:ok, Split.t()} | {:error, map()}
  def split(name) do
    name
    |> Split.RPC.Split.build()
    |> Pool.send_message()
    |> Split.RPC.Split.parse_response()
  end

  @spec splits() :: {:ok, [Split.t()]} | {:error, map()}
  def splits do
    Split.RPC.Splits.build()
    |> Pool.send_message()
    |> Split.RPC.Splits.parse_response()
  end
end
