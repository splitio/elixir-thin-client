defmodule Split.RPCs.Track do
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

  @spec parse_response(map()) :: :ok | :error
  def parse_response(%{"s" => 1, "p" => %{"s" => true}}) do
    :ok
  end

  def parse_response(_) do
    :error
  end
end
