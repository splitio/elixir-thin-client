defmodule Split.Sockets.ConnTest do
  use ExUnit.Case, async: true

  use Split.RPC.Opcodes

  alias Split.Sockets.Conn
  alias Split.RPC.Message

  describe "telemetry events" do
    setup context do
      test_id = :erlang.phash2(context.test)
      socket_path = "/tmp/test-splitd-#{test_id}.sock"
      process_name = :"test-#{test_id}"

      start_supervised!(
        {Split.Test.MockSplitdServer, socket_path: socket_path, name: process_name},
        id: process_name,
        restart: :transient
      )

      Split.Test.MockSplitdServer.wait_until_listening(socket_path)

      {:ok, socket_path: socket_path, splitd_name: process_name}
    end

    test "emits telemetry events for successful connection", %{socket_path: socket_path} do
      ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:split, :connect, :start],
          [:split, :connect, :stop]
        ])

      Conn.new(socket_path) |> Conn.connect()

      assert_received {[:split, :connect, :start], ^ref, _, %{socket_path: ^socket_path}}
      assert_received {[:split, :connect, :stop], ^ref, _, %{socket_path: ^socket_path}}
    end

    test "emits telemetry events for failed connection", %{
      socket_path: socket_path,
      splitd_name: splitd_name
    } do
      ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:split, :connect, :start],
          [:split, :connect, :stop]
        ])

      # Stop the mocked splitd socket so the connection errors
      :ok = stop_supervised(splitd_name)

      assert {:error, _conn, reason} = Conn.new(socket_path) |> Conn.connect()

      assert_received {[:split, :connect, :start], ^ref, _, %{socket_path: ^socket_path}}

      assert_received {[:split, :connect, :stop], ^ref, _,
                       %{error: ^reason, socket_path: ^socket_path}}
    end

    test "emits telemetry events for successful message sending", %{socket_path: socket_path} do
      ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:split, :send, :start],
          [:split, :send, :stop]
        ])

      {:ok, conn} = Conn.new(socket_path) |> Conn.connect()

      # check that telemetry events are emitted for registration message
      assert_register_events(ref)

      message = Message.get_treatment(user_key: "user-id", feature_name: "feature")

      Conn.send_message(conn, message)

      assert_received {[:split, :send, :start], ^ref, _, %{message: ^message}}

      assert_received {[:split, :send, :stop], ^ref, _,
                       %{message: ^message, response: %{"s" => @status_ok}}}
    end

    test "emits telemetry events for failed message sending", %{
      socket_path: socket_path,
      splitd_name: splitd_name
    } do
      ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:split, :send, :start],
          [:split, :send, :stop]
        ])

      {:ok, conn} = Conn.new(socket_path) |> Conn.connect()

      # check that telemetry events are emitted for registration message
      assert_register_events(ref)

      message = Message.get_treatment(user_key: "user-id", feature_name: "feature")

      # Stop the mocked splitd server so the message sending errors
      :ok = stop_supervised(splitd_name)

      assert {:error, _conn, reason} = Conn.send_message(conn, message)

      assert_received {[:split, :send, :start], ^ref, _, %{message: ^message}}

      assert_received {[:split, :send, :stop], ^ref, _, %{error: ^reason, message: ^message}}
    end

    defp assert_register_events(ref) do
      assert_received {[:split, :send, :start], ^ref, _,
                       %{message: %Message{v: 1, o: @register_opcode}}}

      assert_received {[:split, :send, :stop], ^ref, _,
                       %{
                         message: %Message{v: 1, o: @register_opcode},
                         response: %{"s" => @status_ok}
                       }}
    end
  end
end
