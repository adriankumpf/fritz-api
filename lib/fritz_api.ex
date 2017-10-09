defmodule FritzApi do
  @moduledoc """
  Fritz!Box Home Automation API Client for Elixir
  """

  alias FritzApi.{Actor, Commands, SessionId}

  @typedoc """
  - __base__: The base url of the fritzbox. Defaults to "http://fritz.box"
  - __ssl__: SSL options supported by the ssl erlang module
  """
  @type opts :: [base: String.t, ssl: list]

  @doc """
  Get a session ID.

  A valid session ID is required in order to interact with the FritzBox API.

  Each application should only acquire a single session ID since the number of
  sessions to a FritzBox is limited.

  In principle, each session ID has a validity of 60 Minutes whereby the
  validity period gets extended with every access to the API. However, if any
  application tries to access the API with an invalid session ID, all other
  sessions get terminated.

  ## Example

      iex> FritzApi.get_session_id("admin", "changeme")
      {:ok, "879b972027084f61"}

  """
  @spec get_session_id(String.t, String.t, opts) :: {:error, any} | {:ok, String.t}
  defdelegate get_session_id(username, password, opts \\ []), to: SessionId,
                                                              as: :fetch

  @doc """
  Get essential information of all smart home devices.

  ## Example

      iex> FritzApi.get_device_list_infos(sid)
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

  """
  @spec get_device_list_infos(String.t, opts) :: {:error, any} | {:ok, [Actor.t]}
  defdelegate get_device_list_infos(sid, opts \\ []), to: Commands

  @doc """
  Get the actuator identification numbers (AIN) of all known actors.

  ## Example

      iex> FritzApi.get_switch_list(sid, opts)
      {:ok, ["687690315761"]}

  """
  @spec get_switch_list(String.t, opts) :: {:error, any} | {:ok, [String.t]}
  defdelegate get_switch_list(sid, opts \\ []), to: Commands

  @doc """
  Turn on the switch.

  ## Example

      iex> FritzApi.set_switch_on(sid, "687690315761")
      :ok

  """
  @spec set_switch_on(String.t, String.t, opts) :: {:error, any} | :ok
  defdelegate set_switch_on(sid, ain, opts \\ []), to: Commands

  @doc """
  Turn off the switch.

  ## Example

      iex> FritzApi.set_switch_off(sid, "687690315761")
      :ok

  """
  @spec set_switch_off(String.t, String.t, opts) :: {:error, any} | :ok
  defdelegate set_switch_off(sid, ain, opts \\ []), to: Commands

  @doc """
  Toggle the switch.

  ## Example

      iex> FritzApi.set_switch_toggle(sid, "687690315761")
      {:ok, :off}

  """
  @spec set_switch_toggle(String.t, String.t, opts) :: {:error, any} | {:ok, nil | boolean}
  defdelegate set_switch_toggle(sid, ain, opts \\ []), to: Commands

  @doc """
  Get the current switching state.

  Returns `{:ok, nil}` if the state is unkown.

  ## Example

      iex> FritzApi.get_switch_state(sid, "687690315761")
      {:ok, false}

  """
  @spec get_switch_state(String.t, String.t, opts) :: {:error, any} | {:ok, nil | boolean}
  defdelegate get_switch_state(sid, ain, opts \\ []), to: Commands

  @doc """
  Get the current connection state of the actor.

  Returns `{:ok, nil}` if the connection state is unkown.

  ## Example

      iex> FritzApi.get_switch_present(sid, "687690315761")
      {:ok, true}

  """
  @spec get_switch_present(String.t, String.t, opts) :: {:error, any} | {:ok, nil | boolean}
  defdelegate get_switch_present(sid, ain, opts \\ []), to: Commands

  @doc """
  Get the current power consumption (Watt) of the switch.

  Returns `{:ok, nil}` if the state is unkown.

  ## Example

      iex> FritzApi.get_switch_power(sid, "687690315761")
      {:ok, 0.0}

  """
  @spec get_switch_power(String.t, String.t, opts) :: {:error, any} | {:ok, nil | float}
  defdelegate get_switch_power(sid, ain, opts \\ []), to: Commands

  @doc """
  Get the total energy usage (kWh) of the switch.

  Returns `{:ok, nil}` if the state is unkown.

  ## Example

      iex> FritzApi.get_switch_energy(sid, "687690315761")
      {:ok, 0.475}

  """
  @spec get_switch_energy(String.t, String.t, opts) :: {:error, any} | {:ok, nil | float}
  defdelegate get_switch_energy(sid, ain, opts \\ []), to: Commands

  @doc """
  Get the name of the actor.

  ## Example

      iex> FritzApi.get_switch_name(sid, "687690315761")
      {:ok, "FRITZ!DECT #1"}

  """
  @spec get_switch_name(String.t, String.t, opts) :: {:error, any} | {:ok, String.t}
  defdelegate get_switch_name(sid, ain, opts \\ []), to: Commands

  @doc """
  Get the last measured temperature (Celsius) of the actor.

  Returns `{:ok, nil}` if the temperature could not be measured.

  ## Example

      iex> FritzApi.get_temperature(sid, "687690315761")
      {:ok, 23.5}

  """
  @spec get_temperature(String.t, String.t, opts) :: {:error, any} | {:ok, nil | float}
  defdelegate get_temperature(sid, ain, opts \\ []), to: Commands

end
