# SplitThinElixir

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `split_thin_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:split_thin_elixir, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/split_thin_elixir>.

## Testing

### Running splitd for integration testing

There is a convenience makefile target to run `splitd` for integration testing. This is useful to test the client against a real split server. You will need to export the `SPLIT_API_KEY` environment variable exported in your shell to run splitd:

```sh
export SPLIT_API_KEY=your-api-key
make start_splitd
```
