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
    {:fritz_api, "~> 3.0"},
    {:finch, "~> 0.16"}
  ]
end
```

The docs can be found at [hexdocs.pm/fritz_api](https://hexdocs.pm/fritz_api).

## Usage

```elixir
iex> {:ok, client} = FritzApi.Client.new()
...>                 |> FritzApi.Client.login("admin", "changeme")

iex> FritzApi.get_device_list_infos(client)
{:ok, [%FritzApi.Actor{
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

iex> FritzApi.set_switch_off(client, "687690315761")
:ok

iex> FritzApi.get_temperature(client, "687690315761")
{:ok, 23.5}
```

### Automatic Session Refresh

```elixir
defmodule Switch do
  use GenServer

  defmodule State do
    @derive {Inspect, except: [:password]}
    defstruct [:username, :password, :ain, :client]
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def turn_on, do: GenServer.call(__MODULE__, :turn_on)
  def turn_off, do: GenServer.call(__MODULE__, :turn_off)

  @impl true
  def init(opts) do
    client = FritzApi.Client.new(base_url: opts[:host])

    state = %State{
      username: Keyword.fetch!(opts, :username),
      password: Keyword.fetch!(opts, :password),
      ain: Keyword.fetch!(opts, :ain),
      client: client
    }

    {:ok, state, {:continue, :login}}
  end

  @impl true
  def handle_continue(:login, %State{} = state) do
    {:ok, client} = FritzApi.Client.login(state.client, state.username, state.password)
    {:noreply, %State{state | client: client}}
  end

  @impl true
  def handle_call(:turn_on, _from, %State{} = state) do
    {result, state} = refresh_session(&FritzApi.set_switch_on(&1, state.ain), state)
    {:reply, result, state}
  end

  def handle_call(:turn_off, _from, %State{} = state) do
    {result, state} = refresh_session(&FritzApi.set_switch_off(&1, state.ain), state)
    {:reply, result, state}
  end


  defp refresh_session(fun, %State{} = state) do
    with {:error, %FritzApi.Error{reason: :session_expired}} <- fun.(state.client),
         {:ok, client} <- FritzApi.Client.login(state.client, state.username, state.password) do
      {fun.(client), %State{state | client: client}}
    else
      result -> {result, state}
    end
  end
end
```

```elixir
iex> {:ok, pid} = Switch.start_link(username: "admin", password: "admin", ain: "000111222333")
iex> Switch.turn_on(pid)
:ok
```

### Alternative HTTP client

If you need different functionality for the HTTP client, you can define your own module that implements the `FritzApi.HTTPClient` behaviour and set `config :fritz_api, :client` to that module:

```elixir
config :fritz_api, :client, HackneyClient
```

A client based on `:hackney` could look like this:

```elixir
defmodule HackneyClient do
  @behaviour FritzApi.HTTPClient

  @hackney_pool_name :fritz_api_pool

  @impl true
  def child_spec(opts) do
    :hackney_pool.child_spec(@hackney_pool_name, opts)
  end

  @impl true
  def request(method, url, headers, body, opts) do
    opts = Keyword.merge(opts, pool: @hackney_pool_name) ++ [:with_body]

    case :hackney.request(method, url, headers, body, opts) do
      {:ok, _status, _headers, _body} = result -> result
      {:error, _reason} = error -> error
    end
  end
end
```

<!-- MDOC !-->

## References

- [AHA HTTP Interface](https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/AHA-HTTP-Interface.pdf)
- [AVM Technical Note - Session ID](https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/AVM_Technical_Note_-_Session_ID.pdf)
