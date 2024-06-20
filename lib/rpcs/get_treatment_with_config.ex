defmodule Split.RPCs.GetTreatmentWithConfig do
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
      "o" => 0x13,
      "a" => [
        user_key,
        bucketing_key,
        feature_name,
        attributes
      ]
    }
  end

  @impl Split.RPC
  @spec parse_response(map(), Keyword.t()) :: {:ok, Treatment.t()} | {:error, map()}
  def parse_response(%{"s" => 1, "p" => treatment_payload}, _) do
    {:ok, Treatment.build_from_daemon_response(treatment_payload)}
  end

  def parse_response(response, _) do
    {:error, response}
  end
end
