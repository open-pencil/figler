defmodule FigKiwi.FixtureCompare do
  @js ~S'''
  import { readFileSync, writeFileSync } from 'fs';
  import { unzipSync } from 'fflate';
  import { decompress as zstdDecompress } from 'fzstd';
  const { parseFigBuffer } = await import(`${process.cwd()}/packages/core/src/kiwi/fig/parse/core.ts`);

  const [fixture, rawPath, summaryPath] = process.argv.slice(2);
  const bytes = readFileSync(fixture);
  const parsed = parseFigBuffer(bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength));
  const zip = unzipSync(bytes, { filter: file => file.name === 'canvas.fig' || file.name === 'canvas' });
  const canvas = zip['canvas.fig'] ?? zip['canvas'];
  const view = new DataView(canvas.buffer, canvas.byteOffset, canvas.byteLength);
  let offset = 12;
  const schemaLen = view.getUint32(offset, true);
  offset += 4 + schemaLen;
  const dataLen = view.getUint32(offset, true);
  offset += 4;
  writeFileSync(rawPath, zstdDecompress(canvas.slice(offset, offset + dataLen)));

  function b64(value) {
    return Buffer.from(value ?? '', 'utf8').toString('base64url');
  }
  function guid(value) {
    if (!value) return '';
    return `${value.sessionID ?? ''}:${value.localID ?? ''}`;
  }
  function parent(value) {
    if (!value) return ':';
    return `${guid(value.guid)}:${value.position ?? ''}`;
  }
  function nodeLine(prefix, index, node) {
    return [prefix, index, node.type ?? '', b64(node.name), guid(node.guid), parent(node.parentIndex)].join('\t');
  }
  function summary() {
    const nodes = parsed.nodeChanges;
    const typeCounts = new Map();
    for (const node of nodes) typeCounts.set(node.type ?? '', (typeCounts.get(node.type ?? '') ?? 0) + 1);
    const lines = [
      `version\t${parsed.figKiwiVersion}`,
      `nodes\t${nodes.length}`,
      `blobs\t${parsed.blobs.length}`,
      `images\t${parsed.images.length}`,
      ...[...typeCounts.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([type, count]) => `type\t${type}\t${count}`),
      ...nodes.slice(0, 20).map((node, index) => nodeLine('first', index, node)),
      ...nodes.slice(-20).map((node, index) => nodeLine('last', nodes.length - 20 + index, node))
    ];
    return lines.join('\n') + '\n';
  }
  writeFileSync(summaryPath, summary());
  '''

  def run(argv) do
    fixtures =
      case argv do
        [] ->
          [
            "../open-pencil-app/tests/fixtures/gold-preview.fig",
            "../open-pencil-app/tests/fixtures/material3.fig",
            "../open-pencil-app/tests/fixtures/nuxtui.fig"
          ]

        paths ->
          paths
      end

    Enum.each(fixtures, &compare_fixture/1)
  end

  defp compare_fixture(fixture) do
    fixture = Path.expand(fixture)

    tmp_dir =
      Path.join(System.tmp_dir!(), "fig-kiwi-compare-#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp_dir)
    raw_path = Path.join(tmp_dir, "message.bin")
    js_summary_path = Path.join(tmp_dir, "js.tsv")
    js_path = Path.join(tmp_dir, "compare-fixture.ts")
    File.write!(js_path, @js)

    try do
      {_, 0} =
        System.cmd("bun", [js_path, fixture, raw_path, js_summary_path],
          cd: Path.expand("../../open-pencil-app", __DIR__),
          stderr_to_stdout: true
        )

      data = fixture |> read_canvas!() |> FigKiwi.Container.decode() |> Map.fetch!(:data)

      {elapsed, message} = :timer.tc(fn -> FigKiwi.decode_message(data) end)
      {native_elapsed, native_message} = :timer.tc(fn -> FigKiwi.Native.decode_message(data) end)

      elixir_summary = summary(fixture, message)
      js_summary = File.read!(js_summary_path)

      cond do
        message != native_message ->
          IO.puts("native mismatch\t#{fixture}")
          System.halt(1)

        elixir_summary == js_summary ->
          IO.puts(
            "ok\t#{Path.basename(fixture)}\telixir=#{Float.round(elapsed / 1_000_000, 3)}s\tnative=#{Float.round(native_elapsed / 1_000_000, 3)}s"
          )

        true ->
          IO.puts("mismatch\t#{fixture}")
          diff(js_summary, elixir_summary)
          System.halt(1)
      end
    after
      File.rm_rf!(tmp_dir)
    end
  end

  defp summary(fixture, message) do
    nodes = message.node_changes || []
    type_counts = nodes |> Enum.frequencies_by(&enum_name(&1.type)) |> Enum.sort_by(&elem(&1, 0))

    lines =
      [
        "version\t101",
        "nodes\t#{length(nodes)}",
        "blobs\t#{length(message.blobs || [])}",
        "images\t#{image_count(fixture)}"
      ] ++
        Enum.map(type_counts, fn {type, count} -> "type\t#{type}\t#{count}" end) ++
        (nodes
         |> Enum.take(20)
         |> Enum.with_index()
         |> Enum.map(fn {node, index} -> node_line("first", index, node) end)) ++
        (nodes
         |> Enum.take(-20)
         |> Enum.with_index(max(length(nodes) - 20, 0))
         |> Enum.map(fn {node, index} -> node_line("last", index, node) end))

    Enum.join(lines, "\n") <> "\n"
  end

  defp image_count(fixture) do
    {:ok, files} = :zip.extract(String.to_charlist(fixture), [:memory])

    Enum.count(files, fn {name, _data} ->
      name = to_string(name)
      String.starts_with?(name, "images/") and name != "images/"
    end)
  end

  defp read_canvas!(fixture) do
    {:ok, files} = :zip.extract(String.to_charlist(fixture), [:memory])

    files
    |> Enum.find(fn {name, _data} -> to_string(name) in ["canvas.fig", "canvas"] end)
    |> case do
      {_name, data} -> data
      nil -> raise "no canvas.fig entry in #{fixture}"
    end
  end

  defp node_line(prefix, index, node) do
    [
      prefix,
      index,
      enum_name(node.type),
      b64(node.name),
      guid(node.guid),
      parent(node.parent_index)
    ]
    |> Enum.join("\t")
  end

  defp enum_name(nil), do: ""
  defp enum_name(value) when is_atom(value), do: value |> Atom.to_string() |> String.upcase()
  defp enum_name(value), do: to_string(value)

  defp b64(nil), do: ""
  defp b64(value), do: Base.url_encode64(value, padding: false)

  defp guid(nil), do: ""
  defp guid(guid), do: "#{guid.session_id}:#{guid.local_id}"

  defp parent(nil), do: ":"
  defp parent(parent), do: "#{guid(parent.guid)}:#{parent.position || ""}"

  defp diff(expected, actual) do
    expected_lines = String.split(expected, "\n")
    actual_lines = String.split(actual, "\n")

    expected_lines
    |> Enum.zip(actual_lines)
    |> Enum.with_index()
    |> Enum.find(fn {{left, right}, _index} -> left != right end)
    |> case do
      nil ->
        IO.puts("line counts differ: js=#{length(expected_lines)} elixir=#{length(actual_lines)}")

      {{left, right}, index} ->
        IO.puts("line #{index + 1}")
        IO.puts("js:     #{left}")
        IO.puts("elixir: #{right}")
    end
  end
end

FigKiwi.FixtureCompare.run(System.argv())
