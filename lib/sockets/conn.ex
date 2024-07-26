defmodule Split.Sockets.Conn do
  @moduledoc """
  Represents a socket connection to the Splitd daemon.
  """
  require Logger

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

  @default_connect_timeout 1_000
  @default_rcv_timeout 1_000
  @client_id "Splitd_Elixir-" <> to_string(Application.spec(:split, :vsn))

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
    case :gen_tcp.connect({:local, socket_path}, 0, @connect_opts, @default_connect_timeout) do
      {:ok, socket} ->
        conn = %{conn | socket: socket}

        case send_message(conn, registration_message()) do
          {:ok, _conn, _resp} ->
            {:ok, conn}

          {:error, _conn, reason} ->
            Logger.error("Error sending registration message: #{inspect(reason)}")
            {:error, %{conn | socket: nil}, reason}
        end

      {:error, reason} ->
        Logger.error("Error establishing socket connection: #{inspect(reason)}")
        {:error, conn, reason}
    end
  end

  def connect(conn) do
    {:ok, conn}
  end

  defp registration_message() do
    %{
      "v" => 1,
      "o" => 0x00,
      "a" => ["123", @client_id, 1]
    }
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
