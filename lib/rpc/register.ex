defmodule Split.RPC.Register do
  @spec build() :: map()
  def build do
    %{
      "v" => 1,
      "o" => 0x00,
      "a" => ["123", "Splitd_Elixir-" <> app_version(), 1]
    }
  end

  @spec parse_response(map()) :: :ok | :error
  def parse_response(%{"s" => 1}), do: :ok
  def parse_response(_), do: :error

  @spec app_version() :: String.t()
  defp app_version do
    :split |> Application.spec(:vsn) |> to_string()
  end
end
