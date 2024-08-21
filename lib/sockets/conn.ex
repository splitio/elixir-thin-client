defmodule Split.Sockets.Conn do
  @moduledoc """
  Represents a TCP socket connection to the Splitd daemon.
  """
  require Logger
  alias Split.RPC.Message
  alias Split.RPC.Encoder
  alias Split.Telemetry

  @type t :: %__MODULE__{
          socket: port() | nil,
          socket_path: String.t(),
          opts: map()
        }

  defstruct [
    :socket,
    :socket_path,
    :opts
  ]

  @connect_opts [
    mode: :binary,
    active: false,
    packet: 0,
    nodelay: true
  ]

  # Timeout values are the same defaults used by Splitd
  @default_connect_timeout 1000
  @default_rcv_timeout 1000

  @spec new(String.t(), map()) :: t
  def new(socket_path, opts \\ %{}) do
    %__MODULE__{
      socket: nil,
      socket_path: socket_path,
      opts: opts
    }
  end

  @spec connect(t) :: {:ok, t()} | {:error, t(), term()}
  def connect(%__MODULE__{socket: nil, socket_path: socket_path} = conn) do
    connect_timeout = Map.get(conn.opts, :connect_timeout, @default_connect_timeout)

    connect_start = Telemetry.start(:connect, %{socket_path: socket_path})

    case :gen_tcp.connect({:local, socket_path}, 0, @connect_opts, connect_timeout) do
      {:ok, socket} ->
        conn = %{conn | socket: socket}

        case send_message(conn, Message.register()) do
          {:ok, _conn, _resp} ->
            Telemetry.stop(connect_start)
            {:ok, conn}

          {:error, conn, reason} ->
            Telemetry.stop(connect_start, %{error: reason})
            Logger.error("Error sending registration message: #{inspect(reason)}")
            {:error, disconnect(conn), reason}
        end

      {:error, reason} ->
        Telemetry.stop(connect_start, %{error: reason})
        Logger.error("Error establishing socket connection: #{inspect(reason)}")
        {:error, conn, reason}
    end
  end

  def connect(conn) do
    {:ok, conn}
  end

  @spec send_message(t(), term()) :: {:ok, t(), term()} | {:error, t(), term()}
  def send_message(%__MODULE__{socket: nil} = conn, _message) do
    {:error, conn, :socket_disconnected}
  end

  def send_message(conn, message) do
    payload = Encoder.encode(message)
    telemetry_meta = %{request: message}
    send_start = Telemetry.start(:send, telemetry_meta)

    with :ok <- :gen_tcp.send(conn.socket, payload),
         {:ok, response} <- receive_response(conn, telemetry_meta, @default_rcv_timeout) do
      Telemetry.stop(send_start, %{response: response})
      {:ok, conn, response}
    else
      {:error, reason} ->
        Telemetry.stop(send_start, %{error: reason})
        Logger.error("Error receiving response: #{inspect(reason)}")
        {:error, conn, reason}
    end
  end

  @spec transfer_ownership(t(), pid) :: {:ok, t()} | {:error, term()}
  def transfer_ownership(conn, pid) do
    case :gen_tcp.controlling_process(conn.socket, pid) do
      :ok -> {:ok, conn}
      {:error, reason} -> {:error, conn, reason}
    end
  end

  @spec is_open?(t()) :: boolean()
  def is_open?(%__MODULE__{socket: nil}), do: false

  def is_open?(%__MODULE__{socket: socket}) do
    case :inet.peername(socket) do
      {:ok, _} -> true
      _ -> false
    end
  end

  @spec disconnect(t()) :: t()
  def disconnect(%__MODULE__{socket: nil} = conn), do: conn

  def disconnect(%__MODULE__{socket: socket} = conn) do
    :gen_tcp.close(socket)
    %{conn | socket: nil}
  end

  defp receive_response(conn, telemetry_meta, timeout) do
    receive_start = Telemetry.start(:receive, telemetry_meta)

    with {:ok, <<response_size::little-unsigned-size(32)>>} <-
           :gen_tcp.recv(conn.socket, 4, timeout),
         {:ok, response} <- :gen_tcp.recv(conn.socket, response_size, timeout),
         {:ok, unpacked_response} <- Msgpax.unpack(response) do
      Telemetry.stop(receive_start, %{response: unpacked_response})

      {:ok, unpacked_response}
    else
      {:error, reason} ->
        Telemetry.stop(receive_start, %{error: reason})
        {:error, reason}
    end
  end
end
