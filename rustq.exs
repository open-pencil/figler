use RustQ.Config

alias RustQ.Meta.AST, as: MetaAST
alias RustQ.Rustler

unless Code.ensure_loaded?(Figler.Scene.Projection) do
  Code.require_file("lib/figler/scene/projection.ex")
end

unless Code.ensure_loaded?(Figler.Scene.Projection.Native) do
  Code.require_file("lib/figler/scene/projection/native.ex")
end

unless Code.ensure_loaded?(Figler.Native.Entrypoints) do
  Code.require_file("lib/figler/native/entrypoints.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.AtomCache) do
  Code.require_file("codegen/figler/codegen/native/atom_cache.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.SupportFunction) do
  Code.require_file("codegen/figler/codegen/native/support_function.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Focus.Decode) do
  Code.require_file("codegen/figler/codegen/native/focus/decode.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Focus) do
  Code.require_file("codegen/figler/codegen/native/focus.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Scene.FieldSkip) do
  Code.require_file("codegen/figler/codegen/native/scene/field_skip.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Scene.SkipFieldHelpers) do
  Code.require_file("codegen/figler/codegen/native/scene/skip_field_helpers.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Scene.Decode) do
  Code.require_file("codegen/figler/codegen/native/scene/decode.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Scene.Record) do
  Code.require_file("codegen/figler/codegen/native/scene/record.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Scene) do
  Code.require_file("codegen/figler/codegen/native/scene.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native) do
  Code.require_file("codegen/figler/codegen/native.ex")
end

template_source = "native/src/templates/scene_nifs.rs"
template_metadata = template_source |> RustQ.Syn.parse_file!() |> RustQ.Syn.functions()

template_nif_functions =
  Enum.map(Figler.Native.Entrypoints.template_names(), fn name ->
    implementation_name = "#{name}_impl"
    function = Enum.find(template_metadata, &(&1.name == implementation_name))

    function ||
      raise ArgumentError,
            "NIF implementation #{implementation_name} not found in #{template_source}"

    {name, function}
  end)

navigation_nif_functions =
  Enum.map(
    Figler.Native.Entrypoints.navigation_names(),
    &MetaAST.ast!(Figler.Codegen.Native.SupportFunction, &1)
  )

generate "native", "native/src/generated.rs" do
  schema =
    "priv/schema/fig.kiwi"
    |> File.read!()
    |> KiwiCodec.parse_schema!()

  content([
    KiwiCodec.RustlerGenerator.source(schema,
      entrypoints: [],
      definitions: ["Message"],
      features: [:sparse, :skip],
      sparse_messages: :descriptor,
      decoder_sources: ["native/src/runtime.rs"],
      module_prefix: "Figler.Schema"
    ),
    Figler.Codegen.Native.source(schema)
  ])
end

generate "native_stubs", "lib/figler/native/generated_stubs.ex" do
  content(
    Rustler.nif_stubs_from_functions(
      template_nif_functions ++ navigation_nif_functions,
      Figler.Native.GeneratedStubs
    )
  )
end
