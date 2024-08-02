defmodule Split.RPC.GetTreatmentsWithConfig do
  alias Split.Treatment

  @behaviour Split.RPC

  @impl Split.RPC
  @spec build(Keyword.t()) :: map()
  def build(opts) do
    user_key = Keyword.fetch!(opts, :user_key)
    feature_names = Keyword.fetch!(opts, :feature_names)
    bucketing_key = Keyword.get(opts, :bucketing_key, nil)
    attributes = Keyword.get(opts, :attributes, %{})

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

  @impl Split.RPC
  @spec parse_response({:ok, map()}, [String.t()]) :: {:ok, map()} | {:error, term()}
  def parse_response({:ok, %{"s" => 1, "p" => %{"r" => treatment_payloads}}}, opts) do
    treatments = Enum.map(treatment_payloads, &Treatment.build_from_daemon_response/1)
    feature_names = Keyword.fetch!(opts, :feature_names)

    mapped_treatments =
      feature_names
      |> Enum.zip(treatments)
      |> Enum.reduce(%{}, fn {feature_name, treatment}, acc ->
        Map.put(acc, feature_name, treatment)
      end)

    {:ok, mapped_treatments}
  end

  def parse_response({:error, _reason} = response, _) do
    response
  end
end
