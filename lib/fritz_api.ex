defmodule FritzApi do
  @moduledoc """
  API Client for the Fritz!Box Home Automation HTTP Interface
  """

  alias FritzApi.{FritzBox, Helper, DeviceListInfos, SessionId}

  @path "/webservices/homeautoswitch.lua"

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
  def get_session_id(username, password, opts \\ []) do
    SessionId.fetch(username, password, opts)
  end

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
          mode: "manuell",
          state: false
        },
        temperature: %{
          celsius: 23.5,
          offset: 0.0
        }
      }]}

  """
  @spec get_device_list_infos(String.t, opts) :: {:error, any} | {:ok, DeviceListInfos.t}
  def get_device_list_infos(sid, opts \\ []) do
    resp = FritzBox.get(@path, [sid: sid, switchcmd: "getdevicelistinfos"], opts)

    case resp do
      {:ok, devicelist_xml} ->
        {:ok, DeviceListInfos.parse_device_list(devicelist_xml)}
      err ->
        err
    end
  end

  @doc """
  Get the actuator identification numbers (AIN) of all known switches.

  ## Example

      iex> FritzApi.get_switch_list(sid, opts)
      {:ok, ["687690315761"]}

  """
  @spec get_switch_list(String.t, opts) :: {:error, any} | {:ok, [String.t]}
  def get_switch_list(sid, opts \\ []) do
     resp = FritzBox.get(@path, [sid: sid, switchcmd: "getswitchlist"], opts)

    case resp do
      {:ok, ""} -> {:ok, []}
      {:ok, ains} -> {:ok, String.split(ains, ",")}
      err -> err
    end
  end

  @doc """
  Turn on the switch.

  ## Example

      iex> FritzApi.set_switch_on(sid, "687690315761")
      :ok

  """
  @spec set_switch_on(String.t, String.t, opts) :: {:error, any} | :ok
  def set_switch_on(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, [sid: sid, ain: ain, switchcmd: "setswitchon"], opts)

    case resp do
      {:ok, "1"} -> :ok
      err -> err
    end
  end

  @doc """
  Turn off the switch.

  ## Example

      iex> FritzApi.set_switch_off(sid, "687690315761")
      :ok

  """
  @spec set_switch_off(String.t, String.t, opts) :: {:error, any} | :ok
  def set_switch_off(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, [sid: sid, ain: ain, switchcmd: "setswitchoff"], opts)

    case resp do
      {:ok, "0"} -> :ok
      err -> err
    end
  end

  @doc """
  Toggle the switch.

  ## Example

      iex> FritzApi.set_switch_toggle(sid, "687690315761")
      {:ok, :off}

  """
  @spec set_switch_toggle(String.t, String.t, opts) :: {:error, any} | {:ok, :on} | {:ok, :off}
  def set_switch_toggle(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, [sid: sid, ain: ain, switchcmd: "setswitchtoggle"], opts)

    case resp do
      {:ok, "0"} -> {:ok, :off}
      {:ok, "1"} -> {:ok, :on}
      err -> err
    end
  end

  @doc """
  Get the current state of the switch.

  ## Example

      iex> FritzApi.get_switch_state(sid, "687690315761")
      {:ok, :off}

  """
  @spec get_switch_state(String.t, String.t, opts) :: {:error, any} | {:ok, :on} | {:ok, :off}
  def get_switch_state(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, [sid: sid, ain: ain, switchcmd: "getswitchstate"], opts)

    case resp do
      {:ok, "0"} -> {:ok, :off}
      {:ok, "1"} -> {:ok, :on}
      {:ok, "inval"} -> {:error, :unknown}
      err -> err
    end
  end

  @doc """
  Get the current connection state of the actor.

  ## Example

      iex> FritzApi.get_switch_present(sid, "687690315761")
      {:ok, :connected}

  """
  @spec get_switch_present(String.t, String.t, opts) :: {:error, any} | {:ok, :connected} | {:ok, :not_connected}
  def get_switch_present(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, [sid: sid, ain: ain, switchcmd: "getswitchpresent"], opts)

    case resp do
      {:ok, "0"} -> {:ok, :not_connected}
      {:ok, "1"} -> {:ok, :connected}
      err -> err
    end
  end

  @doc """
  Get the current power consumption (Watt) of the switch.

  ## Example

      iex> FritzApi.get_switch_power(sid, "687690315761")
      {:ok, 0.0}

  """
  @spec get_switch_power(String.t, String.t, opts) :: {:error, any} | {:ok, float()}
  def get_switch_power(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, [sid: sid, ain: ain, switchcmd: "getswitchpower"], opts)

    case resp do
      {:ok, "inval"} -> {:error, :unknown}
      {:ok, val} -> {:ok, Helper.parse_float(val, 3)}
      err -> err
    end
  end

  @doc """
  Get the total energy usage (kWh) of the switch.

  ## Example

      iex> FritzApi.get_switch_energy(sid, "687690315761")
      {:ok, 0.475}

  """
  @spec get_switch_energy(String.t, String.t, opts) :: {:error, any} | {:ok, float()}
  def get_switch_energy(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, [sid: sid, ain: ain, switchcmd: "getswitchenergy"], opts)

    case resp do
      {:ok, "inval"} -> {:error, :unknown}
      {:ok, val} -> {:ok, Helper.parse_float(val, 3)}
      err -> err
    end
  end

  @doc """
  Get the name of the actor.

  ## Example

      iex> FritzApi.get_switch_name(sid, "687690315761")
      {:ok, "FRITZ!DECT #1"}

  """
  @spec get_switch_name(String.t, String.t, opts) :: {:error, any} | {:ok, String.t}
  def get_switch_name(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, [sid: sid, ain: ain, switchcmd: "getswitchname"], opts)

    case resp do
      {:ok, val} -> {:ok, val}
      err -> err
    end
  end

  @doc """
  Get the last measured temperature (Celsius) of the actor.

  ## Example

      iex> FritzApi.get_temperature(sid, "687690315761")
      {:ok, 23.5}

  """
  @spec get_temperature(String.t, String.t, opts) :: {:error, any} | {:ok, float()}
  def get_temperature(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, [sid: sid, ain: ain, switchcmd: "gettemperature"], opts)

    case resp do
      {:ok, val} -> {:ok, Helper.parse_float(val, 1)}
      err -> err
    end
  end
end
