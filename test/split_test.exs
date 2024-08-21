defmodule SplitThinElixirTest do
  use ExUnit.Case

  alias Split.Impression
  alias Split.Sockets.Supervisor
  alias Split.Treatment

  setup_all context do
    test_id = :erlang.phash2(context.case)
    socket_path = "/tmp/test-splitd-#{test_id}.sock"

    start_supervised!(
      {Split.Test.MockSplitdServer, socket_path: socket_path, name: :"test-#{test_id}"}
    )

    Split.Test.MockSplitdServer.wait_until_listening(socket_path)

    start_supervised!({Supervisor, %{socket_path: socket_path}})

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

  describe "telemetry" do
    test "emits telemetry spans for rpc calls" do
      ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:split, :rpc, :start],
          [:split, :rpc, :stop]
        ])

      {:ok, split} = Split.split("test-split")
      split_string = inspect(split)

      assert_received {[:split, :rpc, :start], ^ref, _, %{rpc_call: :split}}

      assert_received {[:split, :rpc, :stop], ^ref, _,
                       %{rpc_call: :split, response: ^split_string}}

      :telemetry.detach(ref)
    end
  end
end
