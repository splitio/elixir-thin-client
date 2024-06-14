defmodule Split.RPCs.Register do
  def build do
    %{
      "v" => 1,
      "o" => 0x00,
      "a" => ["123", "Splitd_Elixir-" <> app_version(), 1]
    }
  end

  def parse_response(%{"s" => 1}), do: :ok
  def parse_response(_), do: :error

  defp app_version do
    :split |> Application.spec(:vsn) |> to_string()
  end
end
