# Native Builds

Figler's `.fig` parser is a Rustler NIF compiled from source when the dependency is built. Query-only applications need the Figler NIF but do not need Skia. Rendering applications add the optional `:skia` dependency, which uses published native artifacts when available.

## Supported baseline

The first beta is tested on:

- Elixir 1.19 with Erlang/OTP 27;
- Elixir 1.20 with Erlang/OTP 29;
- stable Rust 1.97;
- x86-64 Linux.

Other platforms may work but are not part of the first-beta CI matrix.

## Install Rust

Install Rust with rustup or your platform package manager, then verify the toolchain:

```bash
rustc --version
cargo --version
```

Fetch and compile Figler normally:

```bash
mix deps.get
mix compile
```

A release builder needs the Rust toolchain even when the final runtime image does not. Copy the compiled Mix release into a smaller runtime image in multi-stage container builds.

## Force a clean native rebuild

If the Rust toolchain, target, or native dependency state changes, rebuild Figler:

```bash
mix deps.clean figler --build
mix deps.compile figler --force
```

Inside a Figler checkout:

```bash
cargo clean --manifest-path native/Cargo.toml
mix compile
```

## Query-only applications

Only add Figler:

```elixir
def deps do
  [{:figler, "~> 0.1.0-beta.1"}]
end
```

The optional Skia dependency is not compiled or loaded by Figler. Calling `Figler.Render.render/2` without Skia returns:

```elixir
{:error, :skia_not_available}
```

Scene analysis, complete-file decoding and encoding, effective graphs, and schema codecs remain available.

## Rendering applications

Add Skia explicitly:

```elixir
def deps do
  [
    {:figler, "~> 0.1.0-beta.1"},
    {:skia, "~> 0.3.7"}
  ]
end
```

Skia may download a matching precompiled artifact. When no artifact is available or a source build is forced, consult the Skia package documentation for platform libraries and build flags.

## Common failures

### Rust compiler not found

```text
could not execute "cargo"
```

Ensure `cargo` is on `PATH` in the same shell or CI step that runs `mix compile`.

### Unsupported Rust version

Update the stable toolchain:

```bash
rustup update stable
rustup default stable
```

Confirm that `rustc --version` meets the supported baseline.

### Stale target artifacts

Errors mentioning an old Rustler, OTP, or target configuration often come from cached build output. Clean both Mix and Cargo artifacts before investigating generated code.

### NIF cannot be loaded

Verify that the release was built for the same operating system, CPU architecture, C runtime, and OTP environment as the runtime image. Do not copy native build output between incompatible Linux distributions or architectures.

### Skia render unavailable

Confirm that `{:skia, "~> 0.3.7"}` is a direct dependency of the consuming application and that its native module compiled or downloaded successfully.

## CI caching

Cache downloads, not opaque cross-platform build products. Good cache candidates include:

- Hex and Rebar package caches;
- Cargo registry and Git checkouts;
- a target directory keyed by OS, architecture, Rust version, OTP version, Elixir version, and lockfile hash.

Never share one compiled NIF cache key across incompatible OTP or target triples.
