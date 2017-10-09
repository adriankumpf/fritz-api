defmodule FritzApi.Client do
  @moduledoc """
  Stateful API Client that takes care of renewing the session id when needed.

  It supports the same commands as the `FritzApi` module.

  ## Usage

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

  """

  alias FritzApi.Client.Server

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start, [opts]},
      restart: :transient,
      bin: :worker
    }
  end

  @timeout 11_000

  @commands_without_ain [
  :get_switch_list,
  :get_device_list_infos,
  ]

  @commands_with_ain [
    :get_switch_energy,
    :get_switch_name,
    :get_switch_power,
    :get_switch_present,
    :get_switch_state,
    :get_temperature,
    :set_switch_off,
    :set_switch_on,
    :set_switch_toggle,
  ]

  def start(opts), do:
    GenServer.start_link(Server, opts, name: __MODULE__)

  for cmd <- @commands_without_ain do
    def unquote(cmd)(), do:
      GenServer.call(__MODULE__, unquote(cmd), @timeout)
  end

  for cmd <- @commands_with_ain do
    def unquote(cmd)(ain), do:
      GenServer.call(__MODULE__, {unquote(cmd), ain}, @timeout)
  end

end
