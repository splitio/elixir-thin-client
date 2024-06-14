socket_path = "/tmp/test-server.sock"

defmodule Split.Test.Server do
  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_port) do
    {:ok, socket} = :gen_tcp.listen(0, active: true, ifaddr: {:local, "/tmp/elixir-splitd.sock"})
    send(self(), :accept)
    {:ok, %{socket: socket}}
  end

  def handle_info(:accept, %{socket: socket} = state) do
    {:ok, _} = :gen_tcp.accept(socket)
    {:noreply, state}
  end

  def handle_info({:tcp, socket, data}, state) do
    # <<_::integer-unsigned-little-size(32), payload::binary>> = data
    payload = Enum.slice(data, 4..-1//1)
    unpacked_payload = Msgpax.unpack!(payload)

    response =
      case Map.get(unpacked_payload, "o") do
        0 -> %{"s" => 1}
        17 -> %{"s" => 1, "p" => %{"t" => "on"}}
        18 -> %{"s" => 1, "p" => %{"t" => "on", "c" => %{"foo" => "bar"}}}
      end

    packed_message = Msgpax.pack!(response, iodata: false)

    payload =
      <<byte_size(packed_message)::integer-unsigned-little-size(32), packed_message::binary>>

    :ok = :gen_tcp.send(socket, payload)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, state), do: {:stop, :normal, state}
  def handle_info({:tcp_error, _}, state), do: {:stop, :normal, state}
end
