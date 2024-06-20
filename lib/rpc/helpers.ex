defmodule Split.RPC.Helpers do
  @spec parse_split(map()) :: Split.t()
  def parse_split(payload) do
    %Split{
      name: Map.get(payload, "n", nil),
      traffic_type: payload["t"],
      killed: payload["k"],
      treatments: payload["s"],
      change_number: payload["c"],
      configurations: payload["f"],
      default_treatment: payload["d"],
      flag_sets: payload["e"]
    }
  end
end
