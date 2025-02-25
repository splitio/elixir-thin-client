defmodule SplitThinElixirTest do
  use ExUnit.Case

  alias Split.Impression
  alias Split.TreatmentWithConfig
  alias Split.SplitView

  setup_all context do
    test_id = :erlang.phash2(context.module)
    address = "/tmp/test-splitd-#{test_id}.sock"

    start_supervised!({Split.Test.MockSplitdServer, address: address, name: :"test-#{test_id}"})

    Split.Test.MockSplitdServer.wait_until_listening(address)

    start_supervised!({Split, address: address})

    :ok
  end

  describe "get_treatment/3" do
    test "returns expected struct" do
      assert "on" =
               Split.get_treatment(
                 "user-id-" <> to_string(Enum.random(1..100_000)),
                 "ethan_test",
                 %{
                   :some_attribute => "some_value"
                 }
               )
    end

    test "emits telemetry event for impression listening" do
      ref = :telemetry_test.attach_event_handlers(self(), [[:split, :impression]])

      Split.get_treatment("user-id-" <> to_string(Enum.random(1..100_000)), "ethan_test")

      assert_received {[:split, :impression], ^ref, _, %{impression: %Impression{}}}
    end
  end

  describe "get_treatment_with_config/3" do
    test "returns expected struct" do
      assert %TreatmentWithConfig{treatment: "on", config: %{"foo" => "bar"}} =
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

  describe "get_treatments/3" do
    test "returns expected map with structs" do
      assert %{"ethan_test" => "on"} =
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

  describe "get_treatments_with_config/3" do
    test "returns expected struct" do
      assert %{"ethan_test" => %TreatmentWithConfig{treatment: "on", config: %{"foo" => "bar"}}} =
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

  describe "get_treatments_by_flag_set/3" do
    test "returns expected map with structs" do
      assert %{"emi_test" => "on"} =
               Split.get_treatments_by_flag_set(
                 "user-id-" <> to_string(Enum.random(1..100_000)),
                 "flag_set_name"
               )
    end

    test "emits telemetry event for impression listening" do
      ref = :telemetry_test.attach_event_handlers(self(), [[:split, :impression]])

      Split.get_treatments_by_flag_set(
        "user-id-" <> to_string(Enum.random(1..100_000)),
        "flag_set_name"
      )

      assert_received {[:split, :impression], ^ref, _, %{impression: %Impression{}}}
    end
  end

  describe "get_treatments_with_config_by_flag_set/3" do
    test "returns expected struct" do
      assert %{"emi_test" => %TreatmentWithConfig{treatment: "on", config: %{"foo" => "bar"}}} =
               Split.get_treatments_with_config_by_flag_set(
                 "user-id-" <> to_string(Enum.random(1..100_000)),
                 "flag_set_name"
               )
    end

    test "emits telemetry event for impression listening" do
      ref = :telemetry_test.attach_event_handlers(self(), [[:split, :impression]])

      Split.get_treatments_with_config_by_flag_set(
        "user-id-" <> to_string(Enum.random(1..100_000)),
        "flag_set_name"
      )

      assert_received {[:split, :impression], ^ref, _, %{impression: %Impression{}}}
    end
  end

  describe "get_treatments_by_flag_sets/3" do
    test "returns expected map with structs" do
      assert %{"emi_test" => "on"} =
               Split.get_treatments_by_flag_sets(
                 "user-id-" <> to_string(Enum.random(1..100_000)),
                 [
                   "flag_set_name"
                 ]
               )
    end

    test "emits telemetry event for impression listening" do
      ref = :telemetry_test.attach_event_handlers(self(), [[:split, :impression]])

      Split.get_treatments_by_flag_sets("user-id-" <> to_string(Enum.random(1..100_000)), [
        "flag_set_name"
      ])

      assert_received {[:split, :impression], ^ref, _, %{impression: %Impression{}}}
    end
  end

  describe "get_treatments_with_config_by_flag_sets/3" do
    test "returns expected struct" do
      assert %{"emi_test" => %TreatmentWithConfig{treatment: "on", config: %{"foo" => "bar"}}} =
               Split.get_treatments_with_config_by_flag_sets(
                 "user-id-" <> to_string(Enum.random(1..100_000)),
                 [
                   "flag_set_name"
                 ]
               )
    end

    test "emits telemetry event for impression listening" do
      ref = :telemetry_test.attach_event_handlers(self(), [[:split, :impression]])

      Split.get_treatments_with_config_by_flag_sets(
        "user-id-" <> to_string(Enum.random(1..100_000)),
        [
          "flag_set_name"
        ]
      )

      assert_received {[:split, :impression], ^ref, _, %{impression: %Impression{}}}
    end
  end

  test "track/5" do
    assert true =
             Split.track(
               "user-id-" <> to_string(Enum.random(1..100_000)),
               "account",
               "purchase",
               100,
               %{"currency" => "USD"}
             )
  end

  test "split_names/0" do
    assert ["ethan_test"] == Split.split_names()
  end

  test "split/1" do
    assert %SplitView{name: "test-split"} =
             Split.split("test-split")
  end

  test "splits/0" do
    assert [%SplitView{name: "test-split"}] = Split.splits()
  end

  describe "telemetry" do
    test "emits telemetry spans for rpc calls" do
      ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:split, :rpc, :start],
          [:split, :rpc, :stop]
        ])

      split = Split.split("test-split")

      assert_received {[:split, :rpc, :start], ^ref, _, %{rpc_call: :split}}

      assert_received {[:split, :rpc, :stop], ^ref, _, %{response: ^split}}
    end
  end
end
