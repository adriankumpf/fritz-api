defmodule Fritzapi.Mixfile do
  use Mix.Project

  def project do
    [
      app: :fritzapi,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
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
      {:sweet_xml, "~> 0.6.5"}
    ]
  end
end
