defmodule FritzApi.Application do
  @moduledoc false

  use Application

  alias FritzApi.Config

  @impl true
  def start(_type, _opts) do
    children = List.wrap(Config.client().child_spec(Config.client_pool_opts()))

    Supervisor.start_link(children, strategy: :one_for_one, name: FritzApi.Supervisor)
  end
end
