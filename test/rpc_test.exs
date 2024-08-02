defmodule Split.RPCTest do
  use ExUnit.Case
  use Mimic

  describe "execute_treatment_rpc/2" do
    test "executes rpc request" do
      rpc = Split.RPC.GetTreatment

      opts = [
        attributes: %{"test" => "test"},
        user_key: "user_key",
        feature_name: "feature_name"
      ]

      expect(Split.Sockets.Pool, :send_message, 1, fn _ ->
        {:ok,
         %{
           "s" => 1,
           "p" => %{
             "t" => "on"
           }
         }}
      end)

      assert {:ok, %{treatment: "on"}} = Split.RPC.execute_treatment_rpc(rpc, opts)
    end
  end
end
