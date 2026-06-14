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
        "native.gen.check",
        "compile --warnings-as-errors",
        "format --check-formatted",
        "rust.fmt --check",
        "rust.check",
        "rust.clippy",
        "test",
        "credo --strict",
        "dialyzer --plt",
        "dialyzer",
        "ex_dna --max-clones 0",
        "reach.check --arch --smells"
      ],
      "native.gen": "rustq.gen native",
      "native.gen.check": "rustq.gen --check native",
      "rust.fmt": &rust_fmt/1,
      "rust.check": &rust_check/1,
      "rust.clippy": &rust_clippy/1
    ]
  end

  defp rust_fmt(args) do
    rust_cmd(["fmt", "--manifest-path", "native/fig_kiwi_native/Cargo.toml"] ++ args)
  end

  defp rust_check(_args) do
    rust_cmd(["check", "--manifest-path", "native/fig_kiwi_native/Cargo.toml"])
  end

  defp rust_clippy(_args) do
    rust_cmd([
      "clippy",
      "--manifest-path",
      "native/fig_kiwi_native/Cargo.toml",
      "--",
      "-D",
      "warnings"
    ])
  end

  defp rust_cmd(args) do
    {_, status} = System.cmd("cargo", args, into: IO.stream(), stderr_to_stdout: true)

    if status != 0 do
      Mix.raise("cargo #{Enum.join(args, " ")} failed")
    end
  end

  defp deps do
    [
      kiwi_codec_dep(),
      rustq_dep(),
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

  defp rustq_dep do
    if File.dir?("../rustq") do
      {:rustq, "~> 0.4", path: "../rustq", runtime: false}
    else
      {:rustq, github: "dannote/rustq", branch: "master", runtime: false}
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
