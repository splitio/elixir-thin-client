# SplitThinElixir

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

After adding the dependency, run `mix deps.get` to fetch the new dependency.

### Usage

In order to use the Split Thin Client, you must start the [Split Daemon (splitd)](https://help.split.io/hc/en-us/articles/18305269686157-Split-Daemon-splitd).

Then you can start the Elixir Split Thin Client, either in your supervision tree:

```elixir
children = [
  {Split, opts}
]
```

Or by starting it manually:

```elixir
Split.Supervisor.start_link(opts)
```

Where `opts` is a keyword list with the following options:

- `:socket_path`: **REQUIRED** The path to the splitd socket file. For example `/var/run/splitd.sock`.
- `:fallback_enabled`: **OPTIONAL** A boolean that indicates wether we should return errors when RPC communication fails or falling back to a default value . Default is `false`.
- `:pool_size`: **OPTIONAL** The size of the pool of connections to the splitd daemon. Default is the number of online schedulers in the Erlang VM (See: https://www.erlang.org/doc/apps/erts/erl_cmd.html).
- `connect_timeout`: **OPTIONAL** The timeout in milliseconds to connect to the splitd daemon. Default is `1000`.

Once you have started Split, you are ready to start interacting with the Split.io splitd's daemon.

## Testing

### Running splitd for integration testing

There is a convenience makefile target to run `splitd` for integration testing. This is useful to test the client against a real split server. You will need to export the `SPLIT_API_KEY` environment variable exported in your shell to run splitd:

```sh
export SPLIT_API_KEY=your-api-key
make start_splitd
```

### Running tests

To run the tests, you can use the following command:

```sh
mix test
```

Or if you want to use TDD fashion with [fswatch](https://github.com/emcrisostomo/fswatch) when test files change:

```sh
fswatch lib test | mix test --listen-on-stdin
```
