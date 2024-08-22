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
  def connect(%__MODULE__{socket: nil, socket_path: socket_path, opts: opts} = conn) do
    connect_timeout = Map.get(conn.opts, :connect_timeout, @default_connect_timeout)

    Telemetry.span(:connect, %{socket_path: socket_path, pool_name: opts[:pool_name]}, fn ->
      case :gen_tcp.connect({:local, socket_path}, 0, @connect_opts, connect_timeout) do
        {:ok, socket} ->
          conn = %{conn | socket: socket}

          case send_message(conn, Message.register()) do
            {:ok, _conn, _resp} ->
              {{:ok, conn}, %{}}

            {:error, conn, reason} ->
              Logger.error("Error sending registration message: #{inspect(reason)}")
              {{:error, disconnect(conn), reason}, %{error: reason}}
          end

        {:error, reason} ->
          Logger.error("Error establishing socket connection: #{inspect(reason)}")
          {{:error, conn, reason}, %{error: reason}}
      end
    end)
  end

  def connect(conn) do
    {:ok, conn}
  end

  @spec send_message(t(), term()) :: {:ok, t(), term()} | {:error, t(), term()}
  def send_message(%__MODULE__{socket: nil} = conn, message) do
    Telemetry.span(:send, %{request: message}, fn ->
      {{:error, conn, :socket_disconnected}, %{error: :socket_disconnected}}
    end)
  end

  def send_message(%__MODULE__{} = conn, message) do
    payload = Encoder.encode(message)
    telemetry_meta = %{request: message}

    Telemetry.span(:send, telemetry_meta, fn ->
      with :ok <- :gen_tcp.send(conn.socket, payload),
           {:ok, response} <- receive_response(conn, telemetry_meta, @default_rcv_timeout) do
        {{:ok, conn, response}, %{response: response}}
      else
        {:error, reason} ->
          Logger.error("Error receiving response: #{inspect(reason)}")
          {{:error, conn, reason}, %{error: reason}}
      end
    end)
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
    Telemetry.span(:receive, telemetry_meta, fn ->
      with {:ok, <<response_size::little-unsigned-size(32)>>} <-
             :gen_tcp.recv(conn.socket, 4, timeout),
           {:ok, response} <- :gen_tcp.recv(conn.socket, response_size, timeout),
           {:ok, unpacked_response} <- Msgpax.unpack(response) do
        {{:ok, unpacked_response}, %{response: unpacked_response}}
      else
        {:error, reason} ->
          {{:error, reason}, %{error: reason}}
      end
    end)
  end
end
