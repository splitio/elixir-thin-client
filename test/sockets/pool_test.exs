defmodule Split.Sockets.PoolTest do
  use ExUnit.Case

  alias Split.RPC.Message
  alias Split.Sockets.Supervisor
  alias Split.Sockets.Pool

  setup_all context do
    socket_path = "/tmp/test-splitd-#{:erlang.phash2(context.case)}.sock"

    Split.Test.MockSplitdServer.start_link(socket_path: socket_path)
    start_supervised!({Supervisor, %{socket_path: socket_path, pool_name: __MODULE__}})

    :ok
  end

  describe "send_message/2" do
    test "should checkout a connection from the pool and send the message" do
      message = Message.splits()

      assert {:ok, message} = Pool.send_message(message, pool_name: __MODULE__)

      assert %{
               "p" => %{
                 "s" => _splits
               },
               "s" => 1
             } = message
    end

    test "emits pool queue telemetry events when message is sent successfully" do
      ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:split, :queue, :start],
          [:split, :queue, :stop]
        ])

      message = Message.splits()

      assert {:ok, _response} = Pool.send_message(message, pool_name: __MODULE__)

      assert_received {[:split, :queue, :start], ^ref, _,
                       %{message: ^message, pool_name: __MODULE__}}

      assert_received {[:split, :queue, :stop], ^ref, _,
                       %{message: ^message, pool_name: __MODULE__}}
    end

    test "emits pool queue telemetry events when message fails" do
      ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:split, :queue, :start],
          [:split, :queue, :stop]
        ])

      # Sending an invalid message to the SplitdMockServer will cause it to close the connection
      message = %{invalid: "message"}

      assert {:error, _reason} = Pool.send_message(message, pool_name: __MODULE__)

      assert_received {[:split, :queue, :start], ^ref, _,
                       %{message: ^message, pool_name: __MODULE__}}

      assert_received {[:split, :queue, :stop], ^ref, _,
                       %{message: ^message, error: :closed, pool_name: __MODULE__}}
    end

    test "emits pool queue telemetry events when worker cannot be checked out" do
      ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:split, :queue, :start],
          [:split, :queue, :exception]
        ])

      message = Message.splits()

      assert {:error, _reason} =
               Pool.send_message(message, pool_name: __MODULE__, checkout_timeout: 0)

      assert_received {[:split, :queue, :start], ^ref, _,
                       %{message: ^message, pool_name: __MODULE__}}

      assert_received {[:split, :queue, :exception], ^ref, _,
                       %{
                         message: ^message,
                         kind: :exit,
                         reason: {:timeout, {NimblePool, :checkout, [__MODULE__]}},
                         stacktrace: _,
                         pool_name: __MODULE__
                       }}
    end
  end
end
