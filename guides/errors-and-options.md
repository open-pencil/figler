# Errors and options

Figler keeps successful query and graph calls lightweight while exposing one
stable malformed-input error shape.

## Error convention

`Figler.Document.open/1` is tuple-returning:

```elixir
case Figler.Document.open(fig_binary) do
  {:ok, document} -> document
  {:error, %Figler.Error{code: code} = error} -> {code, error.context}
end
```

`Figler.Document.open!/1`, message decoders, scene queries, navigation helpers,
and effective-graph functions return their successful value directly and raise
`Figler.Error` for malformed input. This preserves normal query shapes such as
`[Figler.Scene.Node.t()]`, `node | nil`, and `Figler.Scene.Graph.t()`.

A missing query match or GUID that is valid but absent is not an error: list
queries return `[]`, and singular lookups return `nil`. Invalid GUID syntax,
invalid XPath, malformed archives/Kiwi payloads, invalid options, and
insufficient graph projection raise.

`Figler.Error` has three stable fields:

- `:code` — a machine-readable category.
- `:operation` — the public operation or decoding stage that rejected the input.
- `:context` — structured details, such as the invalid GUID or option errors.

Current codes are:

| Code | Meaning |
| --- | --- |
| `invalid_archive` | The input starts as a ZIP archive but cannot be extracted. |
| `missing_canvas` | A FIG archive contains no usable canvas entry. |
| `invalid_document` | A container or Kiwi payload cannot be decoded. |
| `invalid_query` | XPath parsing or evaluation failed. |
| `invalid_guid` | A navigation GUID has invalid syntax. |
| `invalid_options` | Public query, tree, or graph options are malformed. |
| `insufficient_graph_projection` | Reusing a focused graph requires metadata that was not projected. |

Stable operation atoms follow the public surface: `:open_document`,
`:decode_message`, `:decode_sparse_message`, `:decode_message_runtime`,
`:extract_payload`, `:summary`, `:index`, `:query`, the navigation/helper name
(such as `:node` or `:children`), and graph operations prefixed with `graph`.

Application code should branch on fields rather than matching exception-message
text. Native decoder text may appear in `context.reason` for diagnostics but is
not itself a stable API.

## Scene options

`Figler.Scene.query/3`, `by_type/3`, `name_contains/3`, and `text_contains/3`
accept only `fields: :all | [atom | string]`. GUID and node type are always
retained in projected nodes.

`Figler.Scene.find/2` accepts `:type`, `:name`, `:name_contains`, and
`:text_contains`. `Figler.Scene.tree/2` accepts a valid string `:root` and a
non-negative integer `:depth`.

Unknown, conflicting, or malformed values raise `%Figler.Error{
code: :invalid_options}`. Individual failures are available under
`error.context.errors` as `%Figler.OptionError{}` values with `:option`, `:code`,
and `:value`.

## Effective-graph options

`Figler.Scene.graph/2`, `Figler.Scene.Graph.build/2`, and graph profiling/seed
entrypoints validate:

- one of `:stages`, `:only`, or `:until`
- `:skip`
- one of `:focus` or `:root`
- `resolve_variables: false | :known | :preserve`
- `resolve_styles: false | :refs | :known`
- optional projected `:fields`

Resolver stage atoms are listed by `Figler.Scene.Graph.Options.stages/0`.
Unknown stages are errors; `until: :unknown` never silently means the full
pipeline. Graph trees validate `:root` and `:depth`, graph diffs validate
`:root`, and unresolved diagnostics validate `limit: :all | non_neg_integer`.

Rendering has its own option contract in `Figler.Render.Options`; strict-mode
render diagnostics are covered by the [render warning reference](render-warnings.md).
