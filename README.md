# fritz_api

Fritz!Box Home Automation API Client for Elixir
([documentation](https://hexdocs.pm/fritz_api)).

## Installation

Add `fritz_api` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fritz_api, "~> 1.0.0"}
  ]
end
```

## Usage

```elixir
iex> FritzApi.Client.start("admin", "changeme")
iex> FritzApi.Client.get_device_list_infos()
{:ok, [%{
  ain: "687690315761",
  fwversion: "03.87",
  id: 21,
  manufacturer: "AVM",
  name: "FRITZ!DECT #1",
  powermeter: %{energy: 0.475, power: 0.0},
  present: true,
  productname: "FRITZ!DECT 200",
  switch: %{
    devicelock: false,
    lock: false,
    mode: :manual,
    state: false
  },
  temperature: %{
    celsius: 23.5,
    offset: 0.0
  }
}]}
iex> FritzApi.Client.set_switch_off("687690315761")
:ok
iex> FritzApi.Client.get_temperature("687690315761")
{:ok, 23.5}
```

### Options

There are a number of supported options, documented
[here](https://hexdocs.pm/fritz_api/FritzApi.html#t:opts/0), that can be added
when starting the `FritzApi.Client`.

```elixir
iex> FritzApi.Client.start("admin", "changeme", [base: "https://192.168.0.1", ssl: [{:versions, [:'tlsv1.2']}]])
```

### Starting in Supervision Tree

With Elixir > v1.5:

```elixir
# in your application.ex

def start(_type, _args) do
  children = [
    {FritzApi.Client, username: @username, password: @password, opts: @opts}
  ]

  # ...
end
```

Alternatively:

```elixir
def start(_type, _args) do
  import Supervisor.Spec

  children = [
    worker(FritzApi.Client, [[username: @username,
                              password: @password,
                              opts: @opts]], [function: :start])
  ]

  # ...
end
```

## References

* [AHA HTTP Interface](https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/AHA-HTTP-Interface.pdf)
* [AVM Technical Note - Session ID](https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/AVM_Technical_Note_-_Session_ID.pdf)
