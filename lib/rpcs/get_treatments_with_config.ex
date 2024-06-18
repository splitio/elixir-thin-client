defmodule Split.RPCs.GetTreatmentsWithConfig do
  alias Split.Treatment

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
  def parse_response(%{"s" => 1, "p" => %{"r" => treatment_payloads}}, feature_names) do
    treatments = Enum.map(treatment_payloads, &Treatment.build_from_daemon_response/1)

    mapped_treatments =
      feature_names
      |> Enum.zip(treatments)
      |> Enum.reduce(%{}, fn {feature_name, treatment}, acc ->
        Map.put(acc, feature_name, treatment)
      end)

    {:ok, mapped_treatments}
  end

  def parse_response(response, _) do
    {:error, response}
  end
end
