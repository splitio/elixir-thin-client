defmodule Split.RPC.Track do
  @spec build(String.t(), String.t(), String.t(), any(), map()) :: map()
  def build(user_key, traffic_type, event_type, value \\ nil, properties \\ %{}) do
    %{
      "v" => 1,
      "o" => 0x80,
      "a" => [
        user_key,
        traffic_type,
        event_type,
        value,
        properties
      ]
    }
  end

  @spec parse_response({:ok, map()}) :: :ok | :error
  def parse_response({:ok, %{"s" => 1, "p" => %{"s" => true}}}) do
    :ok
  end

  def parse_response({:error, _reason} = _response) do
    :error
  end
end
