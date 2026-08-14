# FritzApi

[![Build Status](https://github.com/adriankumpf/fritz-api/workflows/CI/badge.svg)](https://github.com/adriankumpf/fritz-api/actions)
[![Docs](https://img.shields.io/badge/hex-docs-green.svg?style=flat)](https://hexdocs.pm/fritz_api)
[![Hex.pm](https://img.shields.io/hexpm/v/fritz_api?color=%23714a94)](http://hex.pm/packages/fritz_api)

<!-- MDOC !-->

Fritz!Box Home Automation API Client for Elixir
([documentation](https://hexdocs.pm/fritz_api)).

## Installation

Add `:fritz_api` and `:finch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fritz_api, "~> 3.1"},
    {:finch, "~> 0.16"}
  ]
end
```

## Usage

```elixir
iex> {:ok, client} = FritzApi.Client.new()
...>                 |> FritzApi.Client.login("admin", "changeme")

iex> FritzApi.get_device_list_infos(client)
{:ok, [%FritzApi.Actor{
  ain: "687690315761",
  alert: nil,
  functions: ["Energie Messgerät", "Temperatursensor", "Schaltsteckdose"],
  fwversion: "03.87",
  id: 21,
  manufacturer: "AVM",
  name: "FRITZ!DECT #1",
  powermeter: %FritzApi.Powermeter{energy: 0.475, power: 0.0, voltage: 231.17},
  present: true,
  productname: "FRITZ!DECT 200",
  switch: %FritzApi.Switch{
    devicelock: false,
    lock: false,
    mode: :manual,
    state: false
  },
  temperature: %FritzApi.Temperature{
    celsius: 23.5,
    offset: 0.0
  }
}]}

iex> FritzApi.set_switch_off(client, "687690315761")
:ok

iex> FritzApi.get_temperature(client, "687690315761")
{:ok, 23.5}
```

## References

- [AHA HTTP Interface](https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/AHA-HTTP-Interface.pdf)
- [AVM Technical Note - Session ID](https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/AVM_Technical_Note_-_Session_ID.pdf)
