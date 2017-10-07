defmodule FritzApi.Mixfile do
  use Mix.Project

  def project do
    [
      app: :fritz_api,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),

      # Docs
      name: "FritzApi",
      source_url: "https://github.com/adriankumpf/fritz-api",
      docs: [
        main: "FritzApi",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.13"},
      {:sweet_xml, "~> 0.6.5"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false}
    ]
  end
end
