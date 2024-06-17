defmodule Split.RPCs.Track do
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

  def parse_response(%{"s" => 1, "p" => %{"s" => true}}) do
    :ok
  end

  def parse_response(_) do
    :error
  end
end
