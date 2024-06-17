defmodule Split.RPCs.Split do
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
    {:ok,
     %Split{
       name: Map.get(payload, "n", nil),
       traffic_type: payload["t"],
       killed: payload["k"],
       treatments: payload["s"],
       change_number: payload["c"],
       configurations: payload["f"],
       default_treatment: payload["d"],
       flag_sets: payload["e"]
     }}
  end

  def parse_response(response) do
    {:error, response}
  end
end
