defmodule Split.RPCs.GetTreatmentWithConfig do
  alias Split.Treatment

  @spec build(String.t(), String.t(), String.t() | nil, map() | nil) :: map()
  def build(user_key, feature_name, bucketing_key \\ nil, attributes \\ %{}) do
    %{
      "v" => 1,
      "o" => 0x13,
      "a" => [
        user_key,
        bucketing_key,
        feature_name,
        attributes
      ]
    }
  end

  @spec parse_response(map()) :: {:ok, Treatment.t()} | {:error, map()}
  def parse_response(%{"s" => 1, "p" => treatment_payload}) do
    {:ok, Treatment.build_from_daemon_response(treatment_payload)}
  end

  def parse_response(response) do
    {:error, response}
  end
end
