defmodule Split.RPCs.GetTreatmentsWithConfig do
  @spec build(String.t(), [String.t()], String.t() | nil, map() | nil) :: map()
  def build(user_key, feature_names, bucketing_key \\ nil, attributes \\ %{}) do
    %{
      "v" => 1,
      "o" => 0x14,
      "a" => [
        user_key,
        bucketing_key,
        feature_names,
        attributes
      ]
    }
  end

  @spec parse_response(map(), [String.t()]) :: {:ok, map()} | {:error, map()}
  def parse_response(%{"s" => 1, "p" => %{"r" => treatments}} = _response, feature_names) do
    mapped_treatments =
      feature_names
      |> Enum.zip(treatments)
      |> Enum.reduce(%{}, fn {feature_name, %{"t" => treatment, "c" => config}}, acc ->
        Map.put(acc, feature_name, %{treatment: treatment, config: config})
      end)

    {:ok, %{treatments: mapped_treatments}}
  end

  def parse_response(response, _) do
    {:error, response}
  end
end
