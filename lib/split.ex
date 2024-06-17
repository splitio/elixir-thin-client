defmodule Split do
  @moduledoc """
  Documentation for `Split`.
  """
  alias Split.Sockets.Pool

  @spec get_treatment(String.t(), String.t(), String.t() | nil, map() | nil) ::
          {:ok, map()} | {:error, map()}
  def get_treatment(user_key, feature_name, bucketing_key \\ nil, attributes \\ %{}) do
    user_key
    |> Split.RPCs.GetTreatment.build(feature_name, bucketing_key, attributes)
    |> Pool.send_message()
    |> Split.RPCs.GetTreatment.parse_response()
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
end
