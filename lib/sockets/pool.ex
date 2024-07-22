defmodule Split.Sockets.Pool do
  require Logger

  @behaviour NimblePool

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(opts) do
    NimblePool.start_link(
      worker: {__MODULE__, opts},
      # TODO: make this configurable
      # pool_size: pool_size,
      lazy: true
    )
  end

  def send_message(message) do
    NimblePool.checkout!(
      __MODULE__,
      :checkout,
      fn _caller, port ->
        response = send_message(port, message)
        {response, port}
      end
    )
  end

  def send_message(port, message) do
    packed_message = Msgpax.pack!(message, iodata: false)

    payload =
      <<byte_size(packed_message)::integer-unsigned-little-size(32), packed_message::binary>>

    port
    |> :gen_tcp.send(payload)
    |> receive_response(port)
  end

  @impl NimblePool
  def init_pool(%{socket_path: socket_path} = opts) do
    if File.exists?(socket_path) do
      {:ok, opts}
    else
      {:stop, :socket_not_found}
    end
  end

  @impl NimblePool
  def init_worker(%{socket_path: socket_path} = pool_state) do
    parent = self()

    connect_opts = [
      :binary,
      reuseaddr: true,
      active: false,
      packet: 0
    ]

    # TODO: Make this configurable
    connect_timeout = 1000

    async = fn ->
      case :gen_tcp.connect({:local, socket_path}, 0, connect_opts, connect_timeout) do
        {:ok, socket} ->
          :ok = :gen_tcp.controlling_process(socket, parent)

          :ok =
            socket
            |> send_message(Split.RPC.Register.build())
            |> Split.RPC.Register.parse_response()

          socket

        {:error, _reason} = error ->
          Logger.error("Error establishing socket connection: #{inspect(error)}")
          error
      end
    end

    {:async, async, pool_state}
  end

  @impl NimblePool
  def handle_checkout(:checkout, _port, worker_state, pool_state) do
    {:ok, worker_state, worker_state, pool_state}
  end

  @impl NimblePool
  def terminate_worker(reason, socket, pool_state) when is_port(socket) do
    Logger.error("Terminating worker with reason: #{inspect(reason)}")
    :gen_tcp.close(socket)
    {:ok, pool_state}
  end

  def terminate_worker(_reason, _disconnected_socket, pool_state) do
    {:ok, pool_state}
  end

  defp receive_response({:error, reason}, _port) do
    {:error, reason}
  end

  defp receive_response(:ok, port) do
    with {:ok, <<response_size::little-unsigned-size(32)>>} <- :gen_tcp.recv(port, 4),
         {:ok, response} <- :gen_tcp.recv(port, response_size) do
      Msgpax.unpack!(response)
    else
      error ->
        Logger.error("Error receiving response: #{inspect(error)}")
        error
    end
  end
end
