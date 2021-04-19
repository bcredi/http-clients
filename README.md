# HttpClients

API clients for Bcredi platform.

## Installation

The package can be installed by adding `http_clients` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:http_clients, github: "bcredi/http-clients", branch: "main"}
  ]
end
```

Add Hackney as Tesla default adapter in `config.exs`:

```elixir
config :tesla, adapter: Tesla.Adapter.Hackney
```