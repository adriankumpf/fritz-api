defmodule Fritzapi do
  @moduledoc """
  Documentation for Fritzapi.
  """

  alias Fritzapi.{FritzBox, Helper, DeviceListInfos}

  @path "/webservices/homeautoswitch.lua"

  @doc """
  Get the session id which is required by all other commands.

  Dabei sollte ein Programm zu jeder FRITZ!Box jeweils nur eine Sess ion-ID
  verwenden, da die Anzahl der Sessions zu einer FRITZ!Box beschränkt ist.

  Grundsätzlich können alle dynamisch generierten Seiten nur mit einer
  gültigen Session-ID aufgerufen werden.

  Die Session-ID hat nach Vergabe eine Gültigkeit von 60 Minuten. Die
  Gültigkeitsdauer verlängert sich automatisch bei aktivem Zugriff auf die
  FRITZ!Box.

  However, Versucht eine Anwendung ohne od er mit einer ungültigen Session-ID
  auf die FRITZ!Box zuzugreifen, werden alle aktiven Si tzungen aus
  Sicherheitsgründen beendet.
  """
  def get_session_id(username, password, opts \\ []) do
    Fritzapi.SessionId.fetch(username, password, opts)
  end

  @doc """
  Liefert die grundlegenden Informationen aller SmartHome-Geräte
  """
  def get_device_list_infos(sid, opts \\ []) do
    resp = FritzBox.get(@path, [sid: sid, switchcmd: "getdevicelistinfos"], opts)

    case resp do
      {:ok, devicelist_xml} -> {:ok, DeviceListInfos.parse_device_list(devicelist_xml)}
      err -> err
    end
  end

  @doc """
  Liefert die kommaseparierte AIN/MAC Liste aller bekannten Steckdosen
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
  Schaltet Steckdose ein
  """
  def set_switch_on(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, %{sid: sid, ain: ain, switchcmd: "setswitchon"}, opts)

    case resp do
      {:ok, "1"} -> :ok
      err -> err
    end
  end

  @doc """
  Schaltet Steckdose aus
  """
  def set_switch_off(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, %{sid: sid, ain: ain, switchcmd: "setswitchoff"}, opts)

    case resp do
      {:ok, "0"} -> :ok
      err -> err
    end
  end

  @doc """
  Toggeln der Steckdose ein/aus
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
  Ermittelt Schaltzustand der Steckdose
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
  Ermittelt Verbindungsstatus des Aktors
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
  Ermittelt aktuell über die Steckdose entnommene Leistung
  Leistung in W
  """
  def get_switch_power(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, %{sid: sid, ain: ain, switchcmd: "getswitchpower"}, opts)

    case resp do
      {:ok, "inval"} -> {:error, :unknown}
      {:ok, val} -> {:ok, Helper.parse_float(val, 3) }
      err -> err
    end
  end

  @doc """
  Liefert die über die Steckdose entnommene Ernergiemenge seit Erstinbetriebnahme
  oder Zurücksetzen der Energiestatistik
  Energiemenge in kWh
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
  Liefert Bezeichner des Aktors
  """
  def get_switch_name(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, %{sid: sid, ain: ain, switchcmd: "getswitchname"}, opts)

    case resp do
      {:ok, val} -> {:ok, val}
      err -> err
    end
  end

  @doc """
  Letzte Temperaturinformation des Aktors
  Temperture in Celsius
  """
  def get_temperature(sid, ain, opts \\ []) do
    resp = FritzBox.get(@path, %{sid: sid, ain: ain, switchcmd: "gettemperature"}, opts)

    case resp do
      {:ok, val} -> {:ok, Helper.parse_float(val, 1)}
      err -> err
    end
  end
end
