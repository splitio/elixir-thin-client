defmodule Split.RPC.TrackTest do
  use ExUnit.Case

  alias Split.RPC.Track

  describe "build/4" do
    test "builds the correct map" do
      assert %{
               "v" => 1,
               "o" => 0x80,
               "a" => [
                 "user_key",
                 "traffic_type",
                 "event_type",
                 "value",
                 %{}
               ]
             } == Track.build("user_key", "traffic_type", "event_type", "value", %{})
    end

    test "defaults value and properties" do
      assert %{
               "v" => 1,
               "o" => 0x80,
               "a" => [
                 "user_key",
                 "traffic_type",
                 "event_type",
                 nil,
                 %{}
               ]
             } == Track.build("user_key", "traffic_type", "event_type")
    end
  end
end
