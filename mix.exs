defmodule FritzApi.Mixfile do
  use Mix.Project

  @name "FritzApi"
  @version "2.2.0"
  @url "https://github.com/adriankumpf/fritz-api"

  def project do
    [
      app: :fritz_api,
      version: @version,
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description: "FritzBox Home Automation API Client for Elixir",
      package: package(),
      aliases: [docs: &build_docs/1],
      source_url: "https://github.com/adriankumpf/fritz-api",
      name: @name
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
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/adriankumpf/fritz-api"},
      maintainers: ["Adrian Kumpf"]
    ]
  end

  defp build_docs(_) do
    Mix.Task.run("compile")

    ex_doc = Path.join(Mix.path_for(:escripts), "ex_doc")

    unless File.exists?(ex_doc) do
      raise "cannot build docs because escript for ex_doc is not installed"
    end

    args = [@name, @version, Mix.Project.compile_path()]
    opts = ~w[--main #{@name} --source-ref v#{@version} --source-url #{@url} --config .docs.exs]
    System.cmd(ex_doc, args ++ opts)
    Mix.shell().info("Docs built successfully")
  end
end
