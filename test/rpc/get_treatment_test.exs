defmodule Split.RPC.GetTreatmentTest do
  use ExUnit.Case

  alias Split.RPC.GetTreatment

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
             } ==
               GetTreatment.build(
                 user_key: "user_key",
                 feature_name: "feature_name",
                 bucketing_key: "bucketing_key"
               )
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
             } == GetTreatment.build(user_key: "user_key", feature_name: "feature_name")
    end
  end

  describe "parse_response/1" do
    test "returns {:ok, %{treatment: treatment}}" do
      response = {:ok, %{"s" => 1, "p" => %{"t" => "treatment"}}}

      assert {:ok, %Split.Treatment{treatment: "treatment"}} =
               GetTreatment.parse_response(response, [])
    end

    test "returns {:error, response}" do
      response = {:error, :closed}
      assert response == GetTreatment.parse_response(response, [])
    end
  end
end
