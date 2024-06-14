defmodule Rpcs.GetTreatmentsTest do
  use ExUnit.Case

  alias Split.RPCs.GetTreatments

  describe "build/4" do
    test "builds the correct map" do
      assert %{
               "v" => 1,
               "o" => 0x12,
               "a" => [
                 "user_key",
                 "bucketing_key",
                 ["feature_name"],
                 %{}
               ]
             } == GetTreatments.build("user_key", ["feature_name"], "bucketing_key")
    end

    test "defaults bucketing_key and attributes" do
      assert %{
               "v" => 1,
               "o" => 0x12,
               "a" => [
                 "user_key",
                 nil,
                 ["feature_name"],
                 %{}
               ]
             } == GetTreatments.build("user_key", ["feature_name"])
    end
  end
end
