defmodule FritzApi.Client.Server do
  @moduledoc false

  use GenServer

  alias FritzApi.Client.Impl

  def init(opts) do
    {:ok, Impl.init(opts)}
  end

  def handle_call({cmd, ain}, _from, state) do
    {response, new_state} = Impl.executte_command(cmd, ain, state)
    {:reply, response, new_state}
  end

  def handle_call(cmd, _from, state) do
    {response, new_state} = Impl.executte_command(cmd, nil, state)
    {:reply, response, new_state}
  end
end
