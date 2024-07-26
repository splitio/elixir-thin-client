defmodule Split.RPC.Splits do
  alias Split.RPC.Helpers

  @spec build() :: map()
  def build() do
    %{
      "v" => 1,
      "o" => 0xA2,
      "a" => []
    }
  end

  @spec parse_response({:ok, map()}) :: {:ok, [Split.t()]} | {:error, term()}
  def parse_response({:ok, %{"s" => 1, "p" => %{"s" => splits}}}) do
    Enum.reduce(splits, [], fn split, acc ->
      [Helpers.parse_split(split) | acc]
    end)
    |> then(&{:ok, &1})
  end

  def parse_response({:error, _reason} = response) do
    response
  end
end
