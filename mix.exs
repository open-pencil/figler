defmodule Figler.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/open-pencil/figler"

  def project do
    [
      app: :figler,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      description: "Read and query Figma files from Elixir",
      elixirc_paths: elixirc_paths(Mix.env()),
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

  defp elixirc_paths(:test), do: ["lib", "codegen"]
  defp elixirc_paths(_env), do: ["lib"]

  defp aliases do
    [
      ci: [
        "compile --warnings-as-errors",
        "kiwi.gen.check",
        "rustq.gen --check",
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
      "kiwi.gen.check": &kiwi_gen_check/1,
      "native.gen": "rustq.gen",
      "native.gen.check": "rustq.gen --check",
      "rust.fmt": &rust_fmt/1,
      "rust.check": &rust_check/1,
      "rust.clippy": &rust_clippy/1
    ]
  end

  defp kiwi_gen_check(_args) do
    Mix.Task.run("loadpaths")

    schema_path = "priv/schema/fig.kiwi"
    generated_dir = "lib/generated"

    tmp_dir =
      Path.join(System.tmp_dir!(), "figler-kiwi-gen-check-#{System.unique_integer([:positive])}")

    try do
      schema_path
      |> File.read!()
      |> KiwiCodec.FileGenerator.generate_files!(module_prefix: Figler.Schema, out: tmp_dir)

      compare_generated_files!(tmp_dir, generated_dir)
    after
      File.rm_rf!(tmp_dir)
    end
  end

  defp compare_generated_files!(expected_dir, actual_dir) do
    expected_files = relative_files(expected_dir)
    actual_files = relative_files(actual_dir)

    missing = expected_files -- actual_files
    extra = actual_files -- expected_files

    changed =
      Enum.filter(
        expected_files -- missing,
        &generated_file_changed?(expected_dir, actual_dir, &1)
      )

    case {missing, extra, changed} do
      {[], [], []} ->
        Mix.shell().info("Fresh Kiwi schema modules: #{actual_dir}")

      _stale ->
        Mix.raise("""
        Stale Kiwi schema modules in #{actual_dir}.

        Missing files: #{inspect(missing)}
        Extra files: #{inspect(extra)}
        Changed files: #{inspect(changed)}

        Run:
          mix kiwi.gen priv/schema/fig.kiwi --module-prefix Figler.Schema --out #{actual_dir}
        """)
    end
  end

  defp generated_file_changed?(expected_dir, actual_dir, relative_path) do
    expected_path = Path.join(expected_dir, relative_path)
    actual_path = Path.join(actual_dir, relative_path)

    formatted_file!(expected_path) != formatted_file!(actual_path)
  end

  defp formatted_file!(path) do
    path
    |> File.read!()
    |> Code.format_string!(file: path)
    |> IO.iodata_to_binary()
  end

  defp relative_files(dir) do
    dir
    |> Path.join("**/*")
    |> Path.wildcard()
    |> Enum.reject(&File.dir?/1)
    |> Enum.map(&Path.relative_to(&1, dir))
    |> Enum.sort()
  end

  defp rust_fmt(args) do
    rust_cmd(["fmt", "--manifest-path", "native/Cargo.toml"] ++ args)
  end

  defp rust_check(_args) do
    rust_cmd(["check", "--manifest-path", "native/Cargo.toml"])
  end

  defp rust_clippy(_args) do
    rust_cmd([
      "clippy",
      "--manifest-path",
      "native/Cargo.toml",
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
      json_codec_dep(),
      {:ezstd, "~> 1.2"},
      {:rustler, "~> 0.38"},
      {:skia, "~> 0.3.7", optional: true},
      {:reach, "~> 2.6", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_dna, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_slop, "~> 0.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp kiwi_codec_dep do
    {:kiwi_codec, "~> 0.3.1"}
  end

  defp rustq_dep do
    {:rustq, "~> 1.0.0-rc.3", only: [:dev, :test], runtime: false}
  end

  defp json_codec_dep do
    {:json_codec, "~> 0.1.0"}
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files:
        runtime_files() ++
          [
            "native/Cargo.toml",
            "native/Cargo.lock",
            "native/src",
            "priv/schema",
            "guides/rendering-support.md",
            "mix.exs",
            "README.md",
            "CHANGELOG.md",
            "LICENSE*"
          ]
    ]
  end

  defp runtime_files do
    "lib/**/*.ex"
    |> Path.wildcard()
    |> Enum.reject(&String.starts_with?(&1, "lib/mix/"))
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "guides/rendering-support.md"],
      groups_for_modules: docs_groups_for_modules(),
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp docs_groups_for_modules do
    [
      "Generated schema": [~r/^Figler\.Schema/],
      "Scene graph": [~r/^Figler\.Scene\.Graph$/],
      "Scene graph diagnostics": [~r/^Figler\.Scene\.Graph\.(Oracle|Profile)(\.|$)/],
      "Scene graph internals": [
        ~r/^Figler\.Scene\.Graph\.(Build|Component|Diff|GUID|Nodes|Patch|Provenance|Seed|Symbol)(\.|$)/
      ],
      Documents: [Figler.Document, Figler.Document.Page],
      "Scene projection": [~r/^Figler\.Scene(\.|$)/],
      Rendering: [~r/^Figler\.Render(\.|$)/],
      "Native bridge": [~r/^Figler\.Native(\.|$)/],
      "Code generation": [~r/^Figler\.Codegen/]
    ]
  end
end
