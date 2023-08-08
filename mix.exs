defmodule FritzApi.Mixfile do
  use Mix.Project

  @version "3.0.0-dev"
  @source_url "https://github.com/adriankumpf/fritz-api"

  def project do
    [
      app: :fritz_api,
      version: @version,
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description: "FritzBox Home Automation API Client for Elixir",
      package: package(),
      source_url: @source_url,
      docs: [
        extras: [
          "README.md",
          "CHANGELOG.md",
          "guides/howto/automatic_session_refresh.md"
        ],
        source_ref: "#{@version}",
        source_url: @source_url,
        main: "readme",
        skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
        groups_for_modules: [
          "HTTP Client": ~r/HTTPClient/,
          Models: &(&1[:section] == :models)
        ],
        groups_for_extras: [
          "How-to's": ~r/guides\/howto\/.?/
        ]
      ],
      xref: [exclude: [Finch]]
    ]
  end

  def application do
    [mod: {FritzApi.Application, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:finch, "~> 0.16", optional: true},
      {:elixir_xml_to_map, "~> 3.0"},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:bypass, "~> 2.1", only: :test}
    ]
  end

  defp package do
    [
      files: ["lib", "LICENSE", "mix.exs", "README.md", "CHANGELOG.md"],
      maintainers: ["Adrian Kumpf"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md",
        "GitHub" => @source_url
      }
    ]
  end
end
