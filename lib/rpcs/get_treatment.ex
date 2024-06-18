defmodule Split.RPCs.GetTreatment do
  alias Split.Treatment

  @spec build(String.t(), String.t(), String.t() | nil, map() | nil) :: map()
  def build(user_key, feature_name, bucketing_key \\ nil, attributes \\ %{}) do
    %{
      "v" => 1,
      "o" => 0x11,
      "a" => [
        user_key,
        bucketing_key,
        feature_name,
        attributes
      ]
    }
  end

  @spec parse_response(map()) :: {:ok, map()} | {:error, map()}
  def parse_response(%{"s" => 1, "p" => treatment}) do
    treatment = Treatment.build_from_daemon_response(treatment)
    {:ok, treatment}
  end

  def parse_response(response) do
    {:error, response}
  end
end
