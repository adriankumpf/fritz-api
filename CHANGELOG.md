# Changelog

## 3.1.0 (2026-08-14)

Failures that used to crash now come back as errors: commands return an error
tuple for a response they do not recognize, `FritzApi.Client.login/3` refuses
the unauthenticated session ID instead of handing back an unusable client, and
`FritzApi.Error` messages render for every reason rather than only for atoms.

> #### Check your device function names {: .warning}
>
> Two of the device function classes reported in `FritzApi.Actor` were
> misspelled and are now correct. If you match on either string, update it:
>
> - `"0AVM DECT Repeater"` is now `"AVM DECT Repeater"`
> - `"AVM- Button"` is now `"AVM-Button"`
>
> The function list is also ordered by bit position now, which moves
> `"AVM DECT Repeater"` earlier for devices that report it.

### Fixed

- Commands no longer raise when the FritzBox returns a response they do not
  recognize. They return `{:error, %FritzApi.Error{reason: {:unexpected_response, body}}}`,
  which is what their specs always promised. Previously these escaped as
  `FunctionClauseError`, `MatchError` or `CaseClauseError`. A FritzBox with no
  paired devices was enough to trigger it.
- `FritzApi.Client.login/3` fails with `{:error, %FritzApi.Error{reason: :login_failed}}`
  instead of returning a client holding the unauthenticated session ID
  `"0000000000000000"`. Such a client failed every later call with a misleading
  `:user_not_authorized`.
- `FritzApi.Client.login/3` reports a login response it does not recognize as
  `{:error, %FritzApi.Error{reason: {:unexpected_response, body}}}`. A response
  without a `SessionInfo` element used to escape as a `CaseClauseError`.
- `Exception.message/1` on a `FritzApi.Error` no longer raises for the most
  common reasons. A transport error struct returned by the HTTP client or a
  `{:login_failed, block_time: 60}` tuple used to produce a
  `Protocol.UndefinedError` blob in logs and stack traces.
- `FritzApi.get_switch_list/1` returns `{:ok, []}` for a FritzBox without
  switches, instead of `{:ok, [""]}`. `FritzApi.get_device_list_infos/1`
  likewise returns `{:ok, []}` for an empty device list.
- A malformed XML response is reported as
  `{:error, %FritzApi.Error{reason: {:unexpected_response, body}}}`. The XML
  parser throws, so a truncated response or a captive portal page served as
  `text/xml` used to escape as an uncaught `{:error, ~c"Malformed: ..."}` throw
  that no `case` or `with` at the call site could catch.
- `FritzApi.get_device_list_infos/1` decodes values it does not recognize as
  `nil` instead of raising. A single unexpected switch state or a
  non-numeric `functionbitmask` used to fail the whole device list.
- Two device function classes were misspelled; see the note above.
- `FritzApi.Actor` typed `id` as `String.t()` while it is parsed into an
  integer, and fields that decode to `nil` for an empty XML element were typed
  as non-nil. `FritzApi.set_hkr_target_temperature/3` was specced as `8..28`, an
  integer range that excludes the `21.5` in its own example, and its
  documentation claimed it returns `{:ok, temperature}` rather than `:ok`. The
  radiator controller getters listed `:unknown` among their return values, which
  they never returned.
- The `FritzApi.HTTPClient` documentation showed an example implementing a
  different library's behaviour and a `request/5` callback that does not exist.
- The README and `FritzApi` examples showed a device list the library cannot
  produce: a string `id`, and plain maps where `FritzApi.Powermeter`,
  `FritzApi.Switch` and `FritzApi.Temperature` structs are returned.

### Added

- `FritzApi.Client.execute_command/3` is now public, for the AHA commands that
  `FritzApi` does not wrap.
- `FritzApi.Client.session_id/1` to read the session ID of a logged in client.
- `FritzApi.Error` defines a `t:FritzApi.Error.reason/0` type listing the
  possible failure reasons.
- `t:FritzApi.result/0`, `t:FritzApi.result/1` and `t:FritzApi.hkr_temperature/0`
  name the shapes every command returns.
- `FritzApi.Client.new/1` documents its `:http_client`, `:request_opts` and
  `:session_id` options. All three were already accepted; `:session_id` takes an
  existing session ID, which is how a session survives a restart.

### Changed

- The minimum Elixir version is now 1.15, up from 1.11. Finch and its
  dependencies require it, so the built-in HTTP client could not run on an
  older Elixir anyway.
- `t:FritzApi.Client.t/0` is no longer `@opaque`. It never was in practice, and
  Dialyzer reported an opacity violation for every `FritzApi` command. The
  struct fields remain private; use `FritzApi.Client.session_id/1` to read the
  session ID.
- `FritzApi.HTTPClient.method/0` and `FritzApi.HTTPClient.params/0` were
  removed. Neither was used by a callback.
- `c:FritzApi.HTTPClient.child_spec/1` may return a list of child specifications
  in addition to a single one or `nil`, for clients that need more than one
  supervised process.
- The check for a missing `:finch` dependency moved from the application
  callback into `FritzApi.HTTPClient.Finch`, so the error now names the module
  that needs it.

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
