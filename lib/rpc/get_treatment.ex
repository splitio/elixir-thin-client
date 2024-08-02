defmodule Split.RPC.GetTreatment do
  @doc """
  A treatment represents the result of an Experiment/Feature evaluation.
  """
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
  @spec parse_response({:ok, map()}, Keyword.t()) :: {:ok, Treatment.t()} | {:error, term()}
  def parse_response({:ok, %{"s" => 1, "p" => treatment}} = _resp, _) do
    treatment = Treatment.build_from_daemon_response(treatment)
    {:ok, treatment}
  end

  def parse_response({:error, _reason} = response, _) do
    response
  end
end
