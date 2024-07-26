defmodule Split.Sockets.Conn do
  @moduledoc """
  Represents a socket connection to the Splitd daemon.
  """
  require Logger

  @type t :: %__MODULE__{
          socket: port() | nil,
          socket_path: String.t(),
          last_checkin: integer(),
          opts: Keyword.t()
        }

  defstruct [
    :socket,
    :socket_path,
    :last_checkin,
    :opts
  ]

  @connect_opts [
    mode: :binary,
    active: false,
    packet: 0,
    nodelay: true
  ]

  @default_connect_timeout 1_000
  @default_rcv_timeout 1_000

  @spec new(String.t(), Keyword.t()) :: t
  def new(socket_path, opts \\ []) do
    %__MODULE__{
      socket: nil,
      socket_path: socket_path,
      last_checkin: System.monotonic_time(),
      opts: opts
    }
  end

  @spec connect(t) :: {:ok, t} | {:error, term()}
  def connect(%__MODULE__{socket: nil, socket_path: socket_path} = conn) do
    case :gen_tcp.connect({:local, socket_path}, 0, @connect_opts, @default_connect_timeout) do
      {:ok, socket} ->
        # :ok = :gen_tcp.controlling_process(socket, parent)
        conn = %{conn | socket: socket}

        # TODO: If we cannot register we should close the socket and return an error
        {:ok, conn, _resp} = send_message(conn, Split.RPC.Register.build())

        # |> Split.RPC.Register.parse_response()

        {:ok, conn}

      {:error, reason} ->
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
    message = Msgpax.pack!(message, iodata: false)

    payload = [<<byte_size(message)::integer-unsigned-little-size(32)>>, message]

    with :ok <- :gen_tcp.send(conn.socket, payload),
         {:ok, <<response_size::little-unsigned-size(32)>>} <-
           :gen_tcp.recv(conn.socket, 4, @default_rcv_timeout),
         {:ok, response} <- :gen_tcp.recv(conn.socket, response_size, @default_rcv_timeout) do
      {:ok, conn, Msgpax.unpack!(response)}
    else
      {:error, reason} ->
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
end
