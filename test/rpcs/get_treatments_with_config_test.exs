defmodule Rpcs.GetTreatmentsWithConfigTest do
  use ExUnit.Case

  alias Split.RPCs.GetTreatmentsWithConfig

  describe "build/4" do
    test "builds the correct map" do
      assert %{
               "v" => 1,
               "o" => 0x14,
               "a" => [
                 "user_key",
                 "bucketing_key",
                 ["feature_name"],
                 %{}
               ]
             } ==
               GetTreatmentsWithConfig.build(
                 user_key: "user_key",
                 feature_names: ["feature_name"],
                 bucketing_key: "bucketing_key"
               )
    end

    test "defaults bucketing_key and attributes" do
      assert %{
               "v" => 1,
               "o" => 0x14,
               "a" => [
                 "user_key",
                 nil,
                 ["feature_name"],
                 %{}
               ]
             } ==
               GetTreatmentsWithConfig.build(
                 user_key: "user_key",
                 feature_names: ["feature_name"]
               )
    end
  end
end
