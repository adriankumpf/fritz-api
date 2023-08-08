# Automatic session refresh

At some point every FritzBox session expires. This will result in `{:error, %FritzApi.Error{reason: :session_expired}}` errors.

To refresh a session, call `FritzApi.Client.login/3` again.

## Example

```elixir
defmodule Switch do
  use GenServer

  defmodule State do
    @derive {Inspect, except: [:password]}
    defstruct [:username, :password, :ain, :client]
  end

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)
  def toggle, do: GenServer.call(__MODULE__, :toggle)

  @impl true
  def init(opts) do

    state = %State{
      client: FritzApi.Client.new(),
      username: Keyword.fetch!(opts, :username),
      password: Keyword.fetch!(opts, :password),
      ain: Keyword.fetch!(opts, :ain)
    }

    {:ok, state, {:continue, :login}}
  end

  @impl true
  def handle_continue(:login, %State{} = state) do
    {:ok, client} = FritzApi.Client.login(state.client, state.username, state.password)
    {:noreply, put_in(state.client, client)}
  end

  @impl true
  def handle_call(:toggle, _from, %State{} = state) do
    {result, state} = refresh_session(&FritzApi.set_switch_toggle(&1, state.ain), state)
    {:reply, result, state}
  end

  defp refresh_session(fun, %State{} = state) do
    with {:error, %FritzApi.Error{reason: :session_expired}} <- fun.(state.client),
         {:ok, client} <- FritzApi.Client.login(state.client, state.username, state.password) do
      {fun.(client), put_in(state.client, client)}
    else
      result -> {result, state}
    end
  end
end
```

```elixir
iex> {:ok, pid} = Switch.start_link(username: "admin", password: "admin", ain: "000111222333")
iex> Switch.toggle(pid)
:ok
```
