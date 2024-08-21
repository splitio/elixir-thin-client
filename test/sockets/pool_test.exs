defmodule Split.Sockets.PoolTest do
  use ExUnit.Case

  alias Split.RPC.Message
  alias Split.Sockets.Supervisor
  alias Split.Sockets.Pool
  alias Split.Sockets.PoolMetrics

  import ExUnit.CaptureLog

  setup_all context do
    test_id = :erlang.phash2(context.case)
    socket_path = "/tmp/test-splitd-#{test_id}.sock"

    start_supervised!(
      {Split.Test.MockSplitdServer, socket_path: socket_path, name: :"test-#{test_id}"}
    )

    Split.Test.MockSplitdServer.wait_until_listening(socket_path)

    start_supervised!(
      {Supervisor, %{socket_path: socket_path, pool_name: __MODULE__, pool_size: 10}}
    )

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

      # Sending a disconnect message to the SplitdMockServer will cause it to close the connection
      message = %{"o" => :disconnect}

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

      assert capture_log(fn ->
               assert {:error, _reason} =
                        Pool.send_message(message, pool_name: __MODULE__, checkout_timeout: 0)
             end) =~
               "The Split SDK was unable to provide a connection within the timeout (0 milliseconds)"

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

    test "updates pool utilization metrics" do
      # Sending a wait message to the SplitdMockServer will cause it to sleep for 1 millisecond before responding
      message = %{"o" => :wait}

      {:ok, _response} = Pool.send_message(message, pool_name: __MODULE__)

      assert {:ok,
              %Split.Sockets.PoolMetrics{
                connections_available: 9,
                connections_in_use: 1,
                pool_size: 10
              }} = PoolMetrics.get(__MODULE__)

      # Wait for the connection to be returned back to the pool
      wait_connection_checkin()

      assert {:ok,
              %Split.Sockets.PoolMetrics{
                connections_available: 10,
                connections_in_use: 0,
                pool_size: 10
              }} = PoolMetrics.get(__MODULE__)
    end
  end

  # Waits an an arbitrary amount of milliseconds;
  # enough for the connection to be returned back to the pool.
  defp wait_connection_checkin(), do: Process.sleep(5)
end
