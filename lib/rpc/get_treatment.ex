defmodule Split.RPC.GetTreatment do
  alias Split.Treatment

  @behaviour Split.RPC

  @impl Split.RPC
  @spec build(Keyword.t()) :: map()
  def build(opts) do
    user_key = Keyword.fetch!(opts, :user_key)
    feature_name = Keyword.fetch!(opts, :feature_name)
    bucketing_key = Keyword.get(opts, :bucketing_key, nil)
    attributes = Keyword.get(opts, :attributes, %{})

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

  @impl Split.RPC
  @spec parse_response(map(), Keyword.t()) :: {:ok, map()} | {:error, map()}
  def parse_response(%{"s" => 1, "p" => treatment}, _) do
    treatment = Treatment.build_from_daemon_response(treatment)
    {:ok, treatment}
  end

  def parse_response(response, _) do
    {:error, response}
  end
end
