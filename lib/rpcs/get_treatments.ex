defmodule Split.RPCs.GetTreatments do
  def build(user_key, feature_names, bucketing_key \\ nil, attributes \\ %{}) do
    %{
      "v" => 1,
      "o" => 0x12,
      "a" => [
        user_key,
        bucketing_key,
        feature_names,
        attributes
      ]
    }
  end

  def parse_response(%{"s" => 1, "p" => %{"r" => treatments}} = _response, feature_names) do
    mapped_treatments =
      feature_names
      |> Enum.zip(treatments)
      |> Enum.reduce(%{}, fn {feature_name, %{"t" => treatment}}, acc ->
        Map.put(acc, feature_name, treatment)
      end)

    {:ok, %{treatments: mapped_treatments}}
  end

  def parse_response(response) do
    {:error, response}
  end
end
