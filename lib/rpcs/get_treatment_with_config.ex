defmodule Split.RPCs.GetTreatmentWithConfig do
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

  @spec parse_response(map()) :: {:ok, map()} | {:error, map()}
  def parse_response(%{"s" => 1, "p" => %{"t" => treatment, "c" => config}} = _response) do
    {:ok, %{treatment: treatment, config: config}}
  end

  def parse_response(response) do
    {:error, response}
  end
end
