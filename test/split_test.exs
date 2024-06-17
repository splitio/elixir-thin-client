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

  test "get_treatments_with_config/2" do
    assert {:ok, %{treatments: %{"ethan_test" => %{treatment: "on", config: %{"foo" => "bar"}}}}} =
             Split.get_treatments_with_config("user-id-" <> to_string(Enum.random(1..100_000)), [
               "ethan_test"
             ])
  end

  test "track/3" do
    assert :ok =
             Split.track("user-id-" <> to_string(Enum.random(1..100_000)), "account", "purchase")
  end

  test "split_names/0" do
    assert {:ok, %{split_names: ["ethan_test"]}} == Split.split_names()
  end

  test "split/1" do
    assert {:ok, %Split{name: "test-split"}} =
             Split.split("test-split")
  end

  test "splits/0" do
    assert {:ok, [%Split{name: "test-split"}]} =
             Split.splits()
  end
end
