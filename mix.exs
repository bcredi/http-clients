defmodule HttpClients.MixProject do
  use Mix.Project

  def project do
    [
      app: :http_clients,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test),
    do: ["lib", "test/support", "test/http_clients/fixtures"]

  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.4.0"},
      {:jason, ">= 1.0.0"},
      {:goodies, github: "bcredi/goodies"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.13", only: :test}
    ]
  end
end
