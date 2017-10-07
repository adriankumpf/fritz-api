defmodule Fritzapi do
  @moduledoc """
  Documentation for Fritzapi.
  """

  alias Fritzapi.{Options, Helper}

  @doc"""
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
  def get_session_id(username, password, opts \\ %Options{}) do
    Fritzapi.SessionId.fetch(username, password, opts)
  end

  @doc"""
  Liefert die grundlegenden Informationen aller SmartHome-Geräte
  """
  def get_device_list_infos(sid, opts \\ %Options{}) do
    Fritzapi.DeviceListInfos.fetch(sid, opts)
  end

  @doc"""
  Liefert die kommaseparierte AIN/MAC Liste aller bekannten Steckdosen
  """
  def get_switch_list(sid, opts \\ %Options{}) do
    resp = Fritzapi.Command.execute("getswitchlist", sid, opts)

    resp
    |> String.split(",")
  end

  @doc"""
  Schaltet Steckdose ein
  """
  def set_switch_on(sid, ain, opts \\ %Options{}) do
    resp = Fritzapi.Command.execute("setswitchon", ain, sid, opts)

    case resp do
      "1" -> :ok
      err -> err
    end
  end

  @doc"""
  Schaltet Steckdose aus
  """
  def set_switch_off(sid, ain, opts \\ %Options{}) do
    resp = Fritzapi.Command.execute("setswitchoff", ain, sid, opts)

    case resp do
      "0" -> :ok
      err -> err
    end
  end

  @doc"""
  Toggeln der Steckdose ein/aus
  """
  def set_switch_toggle(sid, ain, opts \\ %Options{}) do
    resp = Fritzapi.Command.execute("setswitchtoggle", ain, sid, opts)

    case resp do
      "0" -> {:ok, :off}
      "1" -> {:ok, :on}
      err -> err
    end
  end

  @doc"""
  Ermittelt Schaltzustand der Steckdose
  """
  def get_switch_state(sid, ain, opts \\ %Options{}) do
    resp = Fritzapi.Command.execute("getswitchstate", ain, sid, opts)

    case resp do
      "0" -> {:ok, :off}
      "1" -> {:ok, :on}
      "inval" -> {:error, :unknown}
      err -> err
    end
  end

  @doc"""
  Ermittelt Verbindungsstatus des Aktors
  """
  def get_switch_present(sid, ain, opts \\ %Options{}) do
    resp = Fritzapi.Command.execute("getswitchpresent", ain, sid, opts)

    case resp do
      "0" -> {:ok, :not_connected}
      "1" -> {:ok, :connected}
      err -> err
    end
  end

  @doc"""
  Ermittelt aktuell über die Steckdose entnommene Leistung
  Leistung in W
  """
  def get_switch_power(sid, ain, opts \\ %Options{}) do
    resp = Fritzapi.Command.execute("getswitchpower", ain, sid, opts)

    case resp do
      "inval" -> {:error, :unknown}
      val when is_binary(val) -> {:ok, Helper.parse_float(val, 3) }
      err -> err
    end
  end

  @doc"""
  Liefert die über die Steckdose entnommene Ernergiemenge seit Erstinbetriebnahme
  oder Zurücksetzen der Energiestatistik
  """
  def get_switch_energy(sid, ain, opts \\ %Options{}) do
    resp = Fritzapi.Command.execute("getswitchenergy", ain, sid, opts)

    case resp do
      "inval" -> {:error, :unknown}
      val when is_binary(val) -> {:ok, Helper.parse_float(val, 3)}
      err -> err
    end
  end

  @doc"""
  Liefert Bezeichner des Aktors
  """
  def get_switch_name(sid, ain, opts \\ %Options{}) do
    resp = Fritzapi.Command.execute("getswitchname", ain, sid, opts)

    case resp do
      val when is_binary(val) -> {:ok, val}
      err -> err
    end
  end

  @doc"""
  Letzte Temperaturinformation des Aktors
  """
  def get_temperature(sid, ain, opts \\ %Options{}) do
    resp = Fritzapi.Command.execute("gettemperature", ain, sid, opts)

    case resp do
      val when is_binary(val) -> {:ok, Helper.parse_float(val, 1)}
      err -> err
    end
  end

end
