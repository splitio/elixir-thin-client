defmodule Split do
  @moduledoc """
  Documentation for `Split`.
  """
  alias Split.Sockets.Pool

  def get_treatment(user_key, feature_name, bucketing_key \\ nil, attributes \\ %{}) do
    user_key
    |> Split.RPCs.GetTreatment.build(feature_name, bucketing_key, attributes)
    |> Pool.send_message()
    |> Split.RPCs.GetTreatment.parse_response()
  end

  def get_treatment_with_config(user_key, feature_name, bucketing_key \\ nil, attributes \\ %{}) do
    user_key
    |> Split.RPCs.GetTreatmentWithConfig.build(feature_name, bucketing_key, attributes)
    |> Pool.send_message()
    |> Split.RPCs.GetTreatmentWithConfig.parse_response()
  end

  def get_treatments(user_key, feature_names, bucketing_key \\ nil, attributes \\ %{}) do
    user_key
    |> Split.RPCs.GetTreatments.build(feature_names, bucketing_key, attributes)
    |> Pool.send_message()
    |> Split.RPCs.GetTreatments.parse_response(feature_names)
  end
end
