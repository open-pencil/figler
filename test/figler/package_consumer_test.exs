defmodule Figler.PackageConsumerTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 900_000

  setup_all do
    root = File.cwd!()

    workspace =
      Path.join(System.tmp_dir!(), "figler-package-#{System.unique_integer([:positive])}")

    package = Path.join(workspace, "package")
    File.mkdir_p!(workspace)
    on_exit(fn -> File.rm_rf!(workspace) end)

    run!(root, "mix", ["hex.build", "--unpack", "--output", package])

    {:ok, root: root, workspace: workspace, package: package}
  end

  test "unpacked package supports query-only consumers", context do
    consumer = copy_fixture!(context.root, context.workspace, "query_consumer")
    env = package_env(context.package, context.workspace)

    run!(consumer, "mix", ["deps.get"], env)
    refute_runtime_codegen_deps!(consumer)
    run!(consumer, "mix", ["test", "--warnings-as-errors"], env)
  end

  test "unpacked package supports Skia rendering consumers", context do
    consumer = copy_fixture!(context.root, context.workspace, "render_consumer")
    env = package_env(context.package, context.workspace)

    run!(consumer, "mix", ["deps.get"], env)
    refute_runtime_codegen_deps!(consumer)
    run!(consumer, "mix", ["test", "--warnings-as-errors"], env)
  end

  defp refute_runtime_codegen_deps!(consumer) do
    lock = File.read!(Path.join(consumer, "mix.lock"))
    refute lock =~ ~s|"rustq"|
    refute lock =~ ~s|"reach"|
  end

  defp copy_fixture!(root, workspace, name) do
    source = Path.join([root, "integration", name])
    destination = Path.join(workspace, name)
    File.cp_r!(source, destination)
    destination
  end

  defp package_env(package, workspace) do
    [
      {"FIGLER_PACKAGE_PATH", package},
      {"MIX_DEPS_PATH", Path.join(workspace, "deps")},
      {"MIX_ENV", "prod"}
    ]
  end

  defp run!(directory, command, args, env \\ []) do
    {output, status} =
      System.cmd(command, args,
        cd: directory,
        env: env,
        stderr_to_stdout: true
      )

    if status != 0 do
      flunk("#{command} #{Enum.join(args, " ")} failed in #{directory}:\n#{output}")
    end

    output
  end
end
