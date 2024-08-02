defmodule Split.RPC.SplitNames do
  @spec build() :: map()
  def build() do
    %{
      "v" => 1,
      "o" => 0xA0,
      "a" => []
    }
  end

  @spec parse_response({:ok, map()}) :: {:ok, map()} | {:error, term()}
  def parse_response({:ok, %{"s" => 1, "p" => %{"n" => split_names}}}) do
    {:ok, %{split_names: split_names}}
  end

  def parse_response({:error, _reason} = response) do
    response
  end
end
