defmodule Rpcs.SplitNamesTest do
  use ExUnit.Case

  alias Split.RPCs.SplitNames

  describe "build/4" do
    test "builds the correct map" do
      assert %{
               "v" => 1,
               "o" => 0xA0,
               "a" => []
             } == SplitNames.build()
    end
  end

  describe "parse_response/1" do
    test "returns {:ok, %{treatment: treatment}}" do
      response = %{"s" => 1, "p" => %{"n" => ["split_name"]}}
      assert {:ok, %{split_names: ["split_name"]}} == SplitNames.parse_response(response)
    end

    test "returns {:error, response}" do
      response = %{"s" => 0}
      assert {:error, %{"s" => 0}} == SplitNames.parse_response(response)
    end
  end
end
