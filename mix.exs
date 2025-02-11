defmodule SplitThinElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :split,
      version: "0.2.0-rc.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      runtime_tools: [:observer],
      package: package(),
      docs: [
        filter_modules: fn mod, _meta ->
          # Skip modules that are not part of the public API
          mod in [
            Split,
            Split.Supervisor,
            Split.SplitView,
            Split.TreatmentWithConfig
          ]
        end
      ]
    ]
  end

  # Package-specific metadata for Hex.pm
  defp package do
    [
      name: "split_thin_sdk",
      description: "Official Split by Harness SDK for feature flags (a.k.a. Split FME)",
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/splitio/elixir-thin-client",
        "Docs" => "https://hexdocs.pm/split_thin_sdk"
      },
      maintainers: ["Emiliano Sanchez", "Nicolas Zelaya", "split-fme-libraries@harness.io"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:msgpax, "~> 2.0"},
      {:nimble_pool, "~> 1.0"},
      {:telemetry, "~> 1.0"},
      # Dev and test dependencies
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
