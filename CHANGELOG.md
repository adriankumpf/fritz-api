# Changelog

## 3.0.0 (2023-08-12)

### Breaking Changes

- Migrate built-in HTTP from `hackney` to `Finch`
- Replace the`:adapter` with the `:client` option

### Upgrade instructions

#### Dependencies

FritzApi now ships with an HTTP client based on `:finch` instead of `:hackney`.

Add `:finch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fritz_api, "~> 3.0"},
    {:finch, "~> 0.16"},
  ]
end
```

#### HTTP client (optional)

1. Remove the `:adapter` configuration from `FritzApi.Client.new/1`:

   ```diff
   {:ok, client} = FritzApi.Client.new(
   -  adapter: {Tesla.Adapter.Gun, []}
   )
   ```

2. In `config/runtime.exs` set the `:fritz_api, :client` option and to your own module that implements the `FritzApi.HTTPClient` behaviour:

   ```diff
   + config :fritz_api,
   +   client: MyGunAdapter
   ```

See the documentation for `FritzApi.HTTPClient` for more information.

## 2.2.0 (2022-12-29)

- Fix deprecation warning
- Update dependencies

## 2.1.0 (2022-02-22)

- Bump elixir_xml_to_map to 3.0

## 2.0.0 (2020-11-27)

FritzApi 2.0 is a major release containing significant changes, particularly around the `FritzApi.Client`.

### Enhancements

- Use [tesla](https://github.com/teamon/tesla) to make the underlying HTTP client configurable

### Breaking Changes

- Replace the stateful `FritzApi.Client` that would need to be started as part of a supervision tree with a simpler struct based approach:
  - Call `FritzApi.Client.new()` to create a new client and `FritzApi.Client.login(client, "user", "password")` to authenticate with the Fritz API
  - See README for an example
- Switch functions like `FritzApi.get_switch_state/2` return `:on`, `:off` atoms instead of a boolean, and `:unknown` if the actor is unavailable
- Introduce a custom error struct (`FritzApi.Error`) and use custom structs for actors (e.g. `FritzApi.Switch`)
- Make hackney an optional dependency. To use the default `hackney` based adapter, add `{:hackney, "~> 1.16"}` to the list of dependencies.
