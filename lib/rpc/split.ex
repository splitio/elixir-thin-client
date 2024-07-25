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

  @spec parse_response(map()) :: {:ok, Split.t()} | {:error, map()}
  def parse_response(%{"s" => 1, "p" => %{"n" => payload}} = _response) do
    {:ok, Helpers.parse_split(payload)}
  end

  def parse_response(response) do
    {:error, response}
  end
end
