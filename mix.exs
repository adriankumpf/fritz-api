defmodule FritzApi.Mixfile do
  use Mix.Project

  def project do
    [
      app: :fritz_api,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      name: "FritzApi",
      source_url: "https://github.com/adriankumpf/fritz-api",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:httpoison, "~> 0.13"},
      {:sweet_xml, "~> 0.6.5"},
    ]
  end

  defp dialyzer do
    [
      flags: [
        "-Wunmatched_returns",
        :error_handling,
        :race_conditions,
        :underspecs
      ],
      ignore_warnings: [
        "dialyzer.ignore-warnings"
      ]
    ]
  end

  defp docs do
    [
      main: "FritzApi",
      extras: ["README.md"]
    ]
  end
end
