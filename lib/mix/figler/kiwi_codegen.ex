defmodule Figler.Mix.KiwiCodegen do
  @moduledoc false

  def load! do
    unless Code.ensure_loaded?(KiwiCodec.RustlerGenerator) do
      files =
        Mix.Project.deps_path()
        |> Path.join("kiwi_codec/codegen/**/*.ex")
        |> Path.wildcard()

      case Kernel.ParallelCompiler.compile(files, return_diagnostics: true) do
        {:ok, _modules, %{compile_warnings: [], runtime_warnings: []}} ->
          :ok

        {:ok, _modules, warnings} ->
          raise "KiwiCodec Rustler generator compiled with warnings: #{inspect(warnings)}"

        {:error, errors, warnings} ->
          raise "KiwiCodec Rustler generator failed to compile: #{inspect({errors, warnings})}"
      end
    end

    :ok
  end
end
