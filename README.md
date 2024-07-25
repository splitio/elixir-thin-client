# SplitThinElixir

**TODO: Add description**

## Getting Started

A step-by-step guide on how to integrate the Split.io thin client for Elixir into your app.

### Installing from Hex.pm

The Split Elixir thin client is publisehd as a package in hex.pm. It can be installed
by adding `split_thin_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:split_thin_elixir, "~> 0.1.0"}
  ]
end
```

## Testing

### Running splitd for integration testing

There is a convenience makefile target to run `splitd` for integration testing. This is useful to test the client against a real split server. You will need to export the `SPLIT_API_KEY` environment variable exported in your shell to run splitd:

```sh
export SPLIT_API_KEY=your-api-key
make start_splitd
```
