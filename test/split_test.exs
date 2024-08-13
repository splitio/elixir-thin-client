defmodule SplitThinElixirTest do
  use ExUnit.Case

  alias Split.Impression
  alias Split.Sockets.Pool
  alias Split.Treatment

  setup_all do
    start_supervised!(
      {NimblePool,
       worker: {Pool, %{socket_path: "/tmp/elixir-splitd.sock"}}, name: Pool, pool_size: 10}
    )

    :ok
  end

  describe "get_treatment/2" do
    test "returns expected struct" do
      assert {:ok, %{treatment: "on"}} =
               Split.get_treatment("user-id-" <> to_string(Enum.random(1..100_000)), "ethan_test")
    end

    test "emits telemetry event for impression listening" do
      ref = :telemetry_test.attach_event_handlers(self(), [[:split, :impression]])

      Split.get_treatment("user-id-" <> to_string(Enum.random(1..100_000)), "ethan_test")

      assert_received {[:split, :impression], ^ref, _, %{impression: %Impression{}}}
    end
  end

  describe "get_treatment_with_config/2" do
    test "returns expected struct" do
      assert {:ok, %Treatment{treatment: "on", config: %{"foo" => "bar"}}} =
               Split.get_treatment_with_config(
                 "user-id-" <> to_string(Enum.random(1..100_000)),
                 "ethan_test"
               )
    end

    test "emits telemetry event for impression listening" do
      ref = :telemetry_test.attach_event_handlers(self(), [[:split, :impression]])

      Split.get_treatment_with_config(
        "user-id-" <> to_string(Enum.random(1..100_000)),
        "ethan_test"
      )

      assert_received {[:split, :impression], ^ref, _, %{impression: %Impression{}}}
    end
  end

  describe "get_treatments/2" do
    test "returns expected map with structs" do
      assert {:ok, %{"ethan_test" => %Treatment{treatment: "on"}}} =
               Split.get_treatments("user-id-" <> to_string(Enum.random(1..100_000)), [
                 "ethan_test"
               ])
    end

    test "emits telemetry event for impression listening" do
      ref = :telemetry_test.attach_event_handlers(self(), [[:split, :impression]])

      Split.get_treatments("user-id-" <> to_string(Enum.random(1..100_000)), ["ethan_test"])

      assert_received {[:split, :impression], ^ref, _, %{impression: %Impression{}}}
    end
  end

  describe "get_treatments_with_config/2" do
    test "returns expected struct" do
      assert {:ok, %{"ethan_test" => %Treatment{treatment: "on", config: %{"foo" => "bar"}}}} =
               Split.get_treatments_with_config(
                 "user-id-" <> to_string(Enum.random(1..100_000)),
                 [
                   "ethan_test"
                 ]
               )
    end

    test "emits telemetry event for impression listening" do
      ref = :telemetry_test.attach_event_handlers(self(), [[:split, :impression]])

      Split.get_treatments_with_config("user-id-" <> to_string(Enum.random(1..100_000)), [
        "ethan_test"
      ])

      assert_received {[:split, :impression], ^ref, _, %{impression: %Impression{}}}
    end
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
    assert {:ok, [%Split{name: "test-split"}]} = Split.splits()
  end
end
