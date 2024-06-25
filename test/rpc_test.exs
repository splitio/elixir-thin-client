defmodule Split.RPCTest do
  use ExUnit.Case
  use Mimic

  alias Split.Treatment

  describe "execute_treatment_rpc/2" do
    test "caches treatment in process" do
      rpc = Split.RPC.GetTreatment

      opts = [
        attributes: %{"test" => "test"},
        user_key: "user_key",
        feature_name: "feature_name"
      ]

      stub(Split.Sockets.Pool, :send_message, fn _ ->
        %{
          "s" => 1,
          "p" => %{
            "t" => "on"
          }
        }
      end)

      assert {:ok, %{treatment: "on"}} = Split.RPC.execute_treatment_rpc(rpc, opts)

      cache_key = Split.RPC.generate_cache_key(opts)
      assert %Treatment{} = Process.get(cache_key)
    end

    test "executes rpc on first request, cache on second" do
      rpc = Split.RPC.GetTreatment

      opts = [
        attributes: %{"test" => "test"},
        user_key: "user_key",
        feature_name: "feature_name"
      ]

      expect(Split.Sockets.Pool, :send_message, 1, fn _ ->
        %{
          "s" => 1,
          "p" => %{
            "t" => "on"
          }
        }
      end)

      assert {:ok, %{treatment: "on"}} = Split.RPC.execute_treatment_rpc(rpc, opts)
      assert {:ok, %{treatment: "on"}} = Split.RPC.execute_treatment_rpc(rpc, opts)
    end
  end
end
