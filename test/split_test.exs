defmodule SplitThinElixirTest do
  use ExUnit.Case

  alias Split.Sockets.Pool

  setup_all do
    child =
      {NimblePool,
       worker: {Pool, %{socket_path: "/tmp/elixir-splitd.sock"}},
       name: Pool,
       lazy: false,
       pool_size: 1}

    {:ok, _pid} = Supervisor.start_link([child], strategy: :one_for_one, restart: :transient)
    :ok
  end

  test "get_treatment/2" do
    assert {:ok, %{treatment: "on"}} =
             Split.get_treatment("user-id-" <> to_string(Enum.random(1..100_000)), "ethan_test")
  end

  test "get_treatment_with_config/2" do
    assert {:ok, %{treatment: "on", config: %{"foo" => "bar"}}} =
             Split.get_treatment_with_config(
               "user-id-" <> to_string(Enum.random(1..100_000)),
               "ethan_test"
             )
  end

  test "get_treatments/2" do
    assert {:ok, %{treatments: %{"ethan_test" => "on"}}} =
             Split.get_treatments("user-id-" <> to_string(Enum.random(1..100_000)), ["ethan_test"])
  end
end
