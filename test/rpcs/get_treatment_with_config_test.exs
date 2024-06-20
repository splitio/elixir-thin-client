defmodule Rpcs.GetTreatmentWithConfigTest do
  use ExUnit.Case

  alias Split.RPCs.GetTreatmentWithConfig
  alias Split.Treatment

  describe "build/4" do
    test "builds the correct map" do
      assert %{
               "v" => 1,
               "o" => 0x13,
               "a" => [
                 "user_key",
                 "bucketing_key",
                 "feature_name",
                 %{}
               ]
             } ==
               GetTreatmentWithConfig.build(
                 user_key: "user_key",
                 feature_name: "feature_name",
                 bucketing_key: "bucketing_key"
               )
    end

    test "defaults bucketing_key and attributes" do
      assert %{
               "v" => 1,
               "o" => 0x13,
               "a" => [
                 "user_key",
                 nil,
                 "feature_name",
                 %{}
               ]
             } == GetTreatmentWithConfig.build(user_key: "user_key", feature_name: "feature_name")
    end
  end

  describe "parse_response/1" do
    test "returns {:ok, %{treatment: treatment}}" do
      response = %{"s" => 1, "p" => %{"t" => "treatment", "c" => %{"foo" => "bar"}}}

      assert {:ok, %Treatment{treatment: "treatment", config: %{"foo" => "bar"}}} =
               GetTreatmentWithConfig.parse_response(response, [])
    end

    test "returns {:error, response}" do
      response = %{"s" => 0}
      assert {:error, response} == GetTreatmentWithConfig.parse_response(response, [])
    end
  end
end
