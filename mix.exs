defmodule FritzApi.Mixfile do
  use Mix.Project

  def project do
    [
      app: :fritz_api,
      version: "1.0.2",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "FritzBox Home Automation API Client for Elixir",
      dialyzer: dialyzer(),
      docs: docs(),
      package: package(),
      source_url: "https://github.com/adriankumpf/fritz-api"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:httpoison, "~> 1.0"},
      {:sweet_xml, "~> 0.6.5"}
    ]
  end

  defp dialyzer do
    [
      flags: [
        "-Wunmatched_returns",
        :error_handling,
        :race_conditions,
        :underspecs
      ]
    ]
  end

  defp docs do
    [
      main: "FritzApi",
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/adriankumpf/fritz-api"},
      maintainers: ["Adrian Kumpf"]
    ]
  end
end
