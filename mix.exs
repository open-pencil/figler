defmodule FigKiwi.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/dannote/fig_kiwi"

  def project do
    [
      app: :fig_kiwi,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      description: "Figma Kiwi schema helpers for Elixir",
      aliases: aliases(),
      dialyzer: [plt_add_apps: [:mix], flags: [:no_opaque]],
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  def cli do
    [preferred_envs: [ci: :test]]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp aliases do
    [
      ci: [
        "compile --warnings-as-errors",
        "format --check-formatted",
        "test",
        "credo --strict",
        "dialyzer --plt",
        "dialyzer",
        "ex_dna --max-clones 0",
        "reach.check --arch --smells"
      ]
    ]
  end

  defp deps do
    [
      kiwi_codec_dep(),
      {:ezstd, "~> 1.2"},
      {:rustler, "~> 0.38"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_dna, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_slop, "~> 0.4", only: [:dev, :test], runtime: false},
      {:reach, "~> 2.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp kiwi_codec_dep do
    if File.dir?("../kiwi_codec") do
      {:kiwi_codec, "~> 0.1.0", path: "../kiwi_codec"}
    else
      {:kiwi_codec, github: "dannote/kiwi_codec", branch: "master"}
    end
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ["lib", "native", "priv", "mix.exs", "README.md", "CHANGELOG.md", "LICENSE*"]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
