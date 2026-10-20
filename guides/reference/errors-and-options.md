# Errors and Options

Figler keeps successful query and graph calls lightweight while exposing one
stable malformed-input error shape.

## Error convention

`Figler.decode/1`, `Figler.encode/1`, and `Figler.Document.open/1` are
tuple-returning:

```elixir
case Figler.decode(fig_binary) do
  {:ok, document} -> document
  {:error, %Figler.Error{code: code} = error} -> {code, error.context}
end
```

Their bang variants, message decoders, scene queries, navigation helpers, and
effective-graph functions return their successful value directly and raise
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
`:decode_document`, `:encode_document`, `:decode_message`,
`:decode_sparse_message`, `:decode_message_runtime`, `:extract_payload`,
`:summary`, `:index`, `:query`, the navigation/helper name
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

`Figler.Scene.graph/2`, `Figler.Scene.Graph.build/2`, and graph profiling
validate:

- one of `:focus` or `:root`
- `resolve_variables: false | :known | :preserve`
- `resolve_styles: false | :refs | :known`
- optional projected `:fields`

Graph trees validate `:root` and `:depth`, graph diffs validate `:root`, and
unresolved diagnostics validate `limit: :all | non_neg_integer`.

## Render errors and safety limits

Rendering has its own option contract in `Figler.Render.Options`; strict-mode
render diagnostics are covered by the [render warning reference](../rendering/rendering-warnings.md).
Its stable error results are:

| Result | Meaning |
| --- | --- |
| `{:error, {:invalid_render_options, errors}}` | An option is unknown, conflicting, or malformed. |
| `{:error, {:unsupported_render_features, warnings}}` | `strict: true` rejected one or more structured diagnostics. |
| `{:error, {:invalid_render_bounds, context}}` | Output bounds are negative, non-finite, larger than 16,384 pixels on one axis, or larger than 67,108,864 total pixels after scaling. |
| `{:error, :skia_not_available}` | The optional Skia dependency is not installed. |

Bounds are checked before image/font loading and canvas allocation. The bounds
context includes the reason, requested scale and dimensions, source bounds, and
active limits. Archive metadata is likewise checked before extraction: archives
with more than 4,096 entries, an entry larger than 256 MiB, or more than 512 MiB
of declared uncompressed content are rejected as `invalid_archive`.

`:background` accepts `:transparent`, the named Skia colors, `#RRGGBB` or
`#RRGGBBAA`, and three/four-channel integer tuples. Invalid colors are option
errors rather than deferred backend exceptions.
