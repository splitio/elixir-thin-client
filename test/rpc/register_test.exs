defmodule Split.RPC.RegisterTest do
  use ExUnit.Case

  alias Split.RPC.Register

  describe "build/4" do
    test "builds the correct map" do
      assert %{
               "v" => 1,
               "o" => 0x00,
               "a" => ["123", "Splitd_Elixir-0.0.0", 1]
             } == Register.build()
    end
  end

  describe "parse_response/1" do
    test "returns {:ok, %{treatment: treatment}}" do
      response = %{"s" => 1}
      assert :ok == Register.parse_response(response)
    end

    test "returns {:error, response}" do
      response = %{"s" => 0}
      assert :error == Register.parse_response(response)
    end
  end
end
