defmodule Figler.MixProject do
  use Mix.Project

  @version "0.1.0-beta.1"
  @source_url "https://github.com/open-pencil/figler"

  def project do
    [
      app: :figler,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      description: "Analyze, transform, and render Figma files from Elixir",
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
      {:ex_doc, "~> 0.34", only: [:dev, :test], runtime: false}
    ]
  end

  defp kiwi_codec_dep do
    {:kiwi_codec, path: "../kiwi_codec", override: true}
  end

  defp rustq_dep do
    {:rustq, "~> 1.0.0-rc.11", only: [:dev, :test], runtime: false}
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
            "guides",
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
      extras: [
        "README.md",
        "CHANGELOG.md",
        "guides/introduction/getting-started.md",
        "guides/introduction/why-figler.md",
        "guides/querying/querying-scenes.md",
        "guides/querying/effective-graphs.md",
        "guides/querying/transforming-files.md",
        "guides/querying/schema-and-codecs.md",
        "guides/rendering/headless-rendering.md",
        "guides/rendering/rendering-support.md",
        "guides/rendering/rendering-warnings.md",
        "guides/rendering/fonts.md",
        "guides/production/performance-and-safety.md",
        "guides/production/native-builds.md",
        "guides/production/compatibility.md",
        "guides/reference/errors-and-options.md"
      ],
      groups_for_extras: [
        Introduction: ~r/guides\/introduction\//,
        "Analysis and Transformation": ~r/guides\/querying\//,
        Rendering: ~r/guides\/rendering\//,
        Production: ~r/guides\/production\//,
        Reference: ~r/guides\/reference\//
      ],
      filter_modules: &public_doc_module?/2,
      groups_for_modules: docs_groups_for_modules(),
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp public_doc_module?(module, _metadata) do
    name = Atom.to_string(module)

    name not in [
      "Elixir.Figler.Render.Projection",
      "Elixir.Figler.Scene.Input",
      "Elixir.Figler.Scene.Projection",
      "Elixir.Figler.Scene.Query",
      "Elixir.Figler.Scene.Tree"
    ] and
      not Enum.any?(
        [
          "Elixir.Figler.Codegen",
          "Elixir.Figler.Native",
          "Elixir.Figler.Render.Skia",
          "Elixir.Mix.Tasks.Figler."
        ],
        &String.starts_with?(name, &1)
      )
  end

  defp docs_groups_for_modules do
    [
      Core: [Figler, Figler.Container, Figler.Sparse],
      "Generated schema": [~r/^Figler\.Schema/],
      Errors: [Figler.Error, Figler.OptionError],
      "Scene graph": [~r/^Figler\.Scene\.Graph(\.Options)?$/],
      "Scene graph diagnostics": [~r/^Figler\.Scene\.Graph\.(Oracle|Profile)(\.|$)/],
      "Scene graph internals": [
        ~r/^Figler\.Scene\.Graph\.(Diff|GUID|Materialize|Occurrence|OpenPencilOracle|Variables)(\.|$)/
      ],
      Documents: [Figler.Document, Figler.Document.Page],
      "Scene queries": [~r/^Figler\.Scene(\.|$)/],
      Rendering: [~r/^Figler\.Render(\.|$)/]
    ]
  end
end
