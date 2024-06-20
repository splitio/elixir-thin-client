defmodule Split.Sockets.Pool do
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
      # pool_size: pool_size,
      lazy: false
    )
  end

  def send_message(message) do
    NimblePool.checkout!(__MODULE__, :checkout, fn _i_dont_know_what_this_is, port ->
      response = send_message(port, message)
      {response, port}
    end)
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
  def init_worker(%{socket_path: socket_path} = pool_state) do
    case :gen_tcp.connect({:local, socket_path}, 0,
           reuseaddr: true,
           active: false,
           mode: :binary,
           packet: 0
         ) do
      {:ok, port} ->
        register_rpc = Split.RPC.Register.build()

        :ok =
          port
          |> send_message(register_rpc)
          |> Split.RPC.Register.parse_response()

        {:ok, port, pool_state}

      _ ->
        {:ok, nil, pool_state}
    end
  end

  @impl NimblePool
  def handle_checkout(:checkout, _port, worker_state, pool_state) do
    {:ok, worker_state, worker_state, pool_state}
  end

  defp receive_response({:error, reason}, _port) do
    {:error, reason}
  end

  defp receive_response(:ok, port) do
    with {:ok, response} <- :gen_tcp.recv(port, 4) do
      response_size = :binary.decode_unsigned(response, :little)

      with {:ok, response} <- :gen_tcp.recv(port, response_size) do
        Msgpax.unpack!(response)
      end
    end
  end
end
