defmodule FritzApi do
  @moduledoc """
  API Client for the Fritz!Box Home Automation HTTP Interface
  """

  alias FritzApi.{FritzBox, Helper, DeviceListInfos, SessionId}

  @path "/webservices/homeautoswitch.lua"

  @doc """
  Get a session ID.

  A valid session ID is required in order to interact with the FritzBox API.

  Each application should only acquire a single session ID since the number of
  sessions to a FritzBox is limited.

  In principle, each session ID has a validity of 60 Minutes whereby the
  validity period gets extended with every access to the API. However, if any
  application tries to access the API with an invalid session ID, all other
  sessions get terminated.
  """
  def get_session_id(username, password, opts \\ []) do
    SessionId.fetch(username, password, opts)
  end

  @doc """
  Get essential information of all smart home devices.
  """
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
  """
  def get_switch_list(sid, opts \\ []) do
     resp = FritzBox.get(@path, %{sid: sid, switchcmd: "getswitchlist"}, opts)

    case resp do
      {:ok, ""} -> {:ok, []}
      {:ok, ains} -> {:ok, String.split(ains, ",")}
      err -> err
    end
  end

  @doc """
  Turn on the switch.
  """
  def set_switch_on(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, %{sid: sid, ain: ain, switchcmd: "setswitchon"}, opts)

    case resp do
      {:ok, "1"} -> :ok
      err -> err
    end
  end

  @doc """
  Turn off the switch.
  """
  def set_switch_off(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, %{sid: sid, ain: ain, switchcmd: "setswitchoff"}, opts)

    case resp do
      {:ok, "0"} -> :ok
      err -> err
    end
  end

  @doc """
  Toggle the switch.
  """
  def set_switch_toggle(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, %{sid: sid, ain: ain, switchcmd: "setswitchtoggle"}, opts)

    case resp do
      {:ok, "0"} -> {:ok, :off}
      {:ok, "1"} -> {:ok, :on}
      err -> err
    end
  end

  @doc """
  Get the current state of the switch.
  """
  def get_switch_state(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, %{sid: sid, ain: ain, switchcmd: "getswitchstate"}, opts)

    case resp do
      {:ok, "0"} -> {:ok, :off}
      {:ok, "1"} -> {:ok, :on}
      {:ok, "inval"} -> {:error, :unknown}
      err -> err
    end
  end

  @doc """
  Get the current connection state of the actor.
  """
  def get_switch_present(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, %{sid: sid, ain: ain, switchcmd: "getswitchpresent"}, opts)

    case resp do
      {:ok, "0"} -> {:ok, :not_connected}
      {:ok, "1"} -> {:ok, :connected}
      err -> err
    end
  end

  @doc """
  Get the current power consumption (Watt) of the switch.
  """
  def get_switch_power(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, %{sid: sid, ain: ain, switchcmd: "getswitchpower"}, opts)

    case resp do
      {:ok, "inval"} -> {:error, :unknown}
      {:ok, val} -> {:ok, Helper.parse_float(val, 3)}
      err -> err
    end
  end

  @doc """
  Get the total energy usage (kWh) of the switch.
  """
  def get_switch_energy(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, %{sid: sid, ain: ain, switchcmd: "getswitchenergy"}, opts)

    case resp do
      {:ok, "inval"} -> {:error, :unknown}
      {:ok, val} -> {:ok, Helper.parse_float(val, 3)}
      err -> err
    end
  end

  @doc """
  Get the name of the actor.
  """
  def get_switch_name(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, %{sid: sid, ain: ain, switchcmd: "getswitchname"}, opts)

    case resp do
      {:ok, val} -> {:ok, val}
      err -> err
    end
  end

  @doc """
  Get the last measured temperature (Celsius) of the actor.
  """
  def get_temperature(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, %{sid: sid, ain: ain, switchcmd: "gettemperature"}, opts)

    case resp do
      {:ok, val} -> {:ok, Helper.parse_float(val, 1)}
      err -> err
    end
  end
end
