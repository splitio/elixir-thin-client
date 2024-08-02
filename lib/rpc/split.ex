defmodule Split.RPC.Split do
  @moduledoc """
  A split represents an Experiment/Feature in Split.io.
  """
  alias Split.RPC.Helpers

  @spec build(String.t()) :: map()
  def build(split_name) do
    %{
      "v" => 1,
      "o" => 0xA1,
      "a" => [split_name]
    }
  end

  @spec parse_response({:ok, map()}) :: {:ok, Split.t()} | {:error, term()}
  def parse_response({:ok, %{"s" => 1, "p" => payload}}) do
    {:ok, Helpers.parse_split(payload)}
  end

  def parse_response({:error, _reason} = response) do
    response
  end
end
