defmodule Rpcs.GetTreatmentTest do
  use ExUnit.Case

  alias Split.RPCs.GetTreatment

  describe "build/4" do
    test "builds the correct map" do
      assert %{
               "v" => 1,
               "o" => 0x11,
               "a" => [
                 "user_key",
                 "bucketing_key",
                 "feature_name",
                 %{}
               ]
             } == GetTreatment.build("user_key", "feature_name", "bucketing_key")
    end

    test "defaults bucketing_key and attributes" do
      assert %{
               "v" => 1,
               "o" => 0x11,
               "a" => [
                 "user_key",
                 nil,
                 "feature_name",
                 %{}
               ]
             } == GetTreatment.build("user_key", "feature_name")
    end
  end

  describe "parse_response/1" do
    test "returns {:ok, %{treatment: treatment}}" do
      response = %{"s" => 1, "p" => %{"t" => "treatment"}}
      assert {:ok, %{treatment: "treatment"}} == GetTreatment.parse_response(response)
    end

    test "returns {:error, response}" do
      response = %{"s" => 0}
      assert {:error, response} == GetTreatment.parse_response(response)
    end
  end
end
