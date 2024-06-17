defmodule Split.RPCs.Splits do
  alias Split.RPCs.Helpers

  @spec build() :: map()
  def build() do
    %{
      "v" => 1,
      "o" => 0xA2,
      "a" => []
    }
  end

  @spec parse_response(map()) :: {:ok, [Split.t()]} | {:error, map()}
  def parse_response(%{"s" => 1, "p" => %{"s" => splits}} = _response) do
    Enum.reduce(splits, [], fn split, acc ->
      [Helpers.parse_split(split) | acc]
    end)
    |> then(&{:ok, &1})
  end

  def parse_response(response) do
    {:error, response}
  end
end
