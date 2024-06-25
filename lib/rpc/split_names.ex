defmodule Split.RPC.SplitNames do
  @spec build() :: map()
  def build() do
    %{
      "v" => 1,
      "o" => 0xA0,
      "a" => []
    }
  end

  @spec parse_response(map()) :: {:ok, map()} | {:error, map()}
  def parse_response(%{"s" => 1, "p" => %{"n" => split_names}} = _response) do
    {:ok, %{split_names: split_names}}
  end

  def parse_response(response) do
    {:error, response}
  end
end
