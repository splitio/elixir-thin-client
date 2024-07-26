defmodule Split.RPC.SplitTest do
  use ExUnit.Case

  alias Split.RPC.Split, as: SplitRPC

  describe "build/1" do
    test "builds the correct map" do
      assert %{
               "v" => 1,
               "o" => 0xA1,
               "a" => ["test-split"]
             } == SplitRPC.build("test-split")
    end
  end

  describe "parse_response/1" do
    test "returns {:ok, %{treatment: treatment}}" do
      response =
        {:ok,
         %{
           "s" => 1,
           "p" => %{
             "n" => %{
               "n" => "test-split",
               "t" => "traffic_type",
               "k" => false,
               "s" => ["on", "off"],
               "c" => 12345,
               "f" => %{"on" => "foo"},
               "d" => "default_treatment",
               "e" => ["flag_set"]
             }
           }
         }}

      assert {:ok,
              %Split{
                name: "test-split",
                traffic_type: "traffic_type",
                killed: false,
                treatments: ["on", "off"],
                change_number: 12345,
                configurations: %{"on" => "foo"},
                default_treatment: "default_treatment",
                flag_sets: ["flag_set"]
              }} == SplitRPC.parse_response(response)
    end

    test "returns {:error, response}" do
      response = %{"s" => 0}
      assert {:error, %{"s" => 0}} == SplitRPC.parse_response(response)
    end
  end
end
