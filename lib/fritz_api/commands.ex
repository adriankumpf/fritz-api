defmodule FritzApi.Commands do
  @moduledoc false

  alias FritzApi.Commands.{Helper, DeviceListInfos}
  alias FritzApi.FritzBox

  @path "/webservices/homeautoswitch.lua"

  @type opts :: [base: String.t, ssl: list]

  defp execute_command(cmd, sid, [ain: ain], opts) do
    FritzBox.get(@path, [switchcmd: cmd, sid: sid, ain: ain], opts)
    |> translate_actor_error
  end
  defp execute_command(cmd, sid, opts) do
    FritzBox.get(@path, [switchcmd: cmd, sid: sid], opts)
  end

  defp translate_actor_error({:error, :bad_request}), do:
    {:error, :actor_not_found}
  defp translate_actor_error(other), do:
    other

  # COMMANDS

  @spec get_device_list_infos(String.t, opts) :: {:error, any} | {:ok, DeviceListInfos.t}
  def get_device_list_infos(sid, opts) do
    case execute_command("getdevicelistinfos", sid, opts) do
      {:ok, devicelist_xml} ->
        {:ok, DeviceListInfos.parse_device_list(devicelist_xml)}
      {:error, _} = err ->
        err
    end
  end

  @spec get_switch_list(String.t, opts) :: {:error, any} | {:ok, [String.t]}
  def get_switch_list(sid, opts) do
    case execute_command("getswitchlist", sid, opts) do
      {:ok, ""} -> {:ok, []}
      {:ok, ains} -> {:ok, String.split(ains, ",")}
      {:error, _} = err -> err
    end
  end

  @spec set_switch_on(String.t, String.t, opts) :: {:error, any} | :ok
  def set_switch_on(sid, ain, opts) do
    case execute_command("setswitchon", sid, [ain: ain], opts) do
      {:ok, "1"} -> :ok
      {:error, _} = err -> err
    end
  end

  @spec set_switch_off(String.t, String.t, opts) :: {:error, any} | :ok
  def set_switch_off(sid, ain, opts) do
    case execute_command("setswitchoff", sid, [ain: ain], opts) do
      {:ok, "0"} -> :ok
      {:error, _} = err -> err
    end
  end

  @spec set_switch_toggle(String.t, String.t, opts) :: {:error, any} | {:ok, :on | :off}
  def set_switch_toggle(sid, ain, opts) do
    case execute_command("setswitchtoggle", sid, [ain: ain], opts) do
      {:ok, "0"} -> {:ok, :off}
      {:ok, "1"} -> {:ok, :on}
      {:error, _} = err -> err
    end
  end

  @spec get_switch_state(String.t, String.t, opts) :: {:error, any} | {:ok, :on | :off | nil}
  def get_switch_state(sid, ain, opts) do
    case execute_command("getswitchstate", sid, [ain: ain], opts) do
      {:ok, "0"} -> {:ok, :off}
      {:ok, "1"} -> {:ok, :on}
      {:ok, "inval"} -> {:ok, nil}
      {:error, _} = err -> err
    end
  end

  @spec get_switch_present(String.t, String.t, opts) :: {:error, any} | {:ok, :connected | :not_connected}
  def get_switch_present(sid, ain, opts) do
    case execute_command("getswitchpresent", sid, [ain: ain], opts) do
      {:ok, "0"} -> {:ok, :not_connected}
      {:ok, "1"} -> {:ok, :connected}
      {:error, _} = err -> err
    end
  end

  @spec get_switch_power(String.t, String.t, opts) :: {:error, any} | {:ok, nil | float}
  def get_switch_power(sid, ain, opts) do
    case execute_command("getswitchpower", sid, [ain: ain], opts) do
      {:ok, "inval"} -> {:ok, nil}
      {:ok, val} -> {:ok, Helper.parse_float(val, 3)}
      {:error, _} = err -> err
    end
  end

  @spec get_switch_energy(String.t, String.t, opts) :: {:error, any} | {:ok, nil | float}
  def get_switch_energy(sid, ain, opts) do
    case execute_command("getswitchenergy", sid, [ain: ain], opts) do
      {:ok, "inval"} -> {:ok, nil}
      {:ok, val} -> {:ok, Helper.parse_float(val, 3)}
      {:error, _} = err -> err
    end
  end

  @spec get_switch_name(String.t, String.t, opts) :: {:error, any} | {:ok, String.t}
  def get_switch_name(sid, ain, opts) do
    execute_command("getswitchname", sid, [ain: ain], opts)
  end

  @spec get_temperature(String.t, String.t, opts) :: {:error, any} | {:ok, float}
  def get_temperature(sid, ain, opts) do
    case execute_command("gettemperature", sid, [ain: ain], opts) do
      {:ok, val} -> {:ok, Helper.parse_float(val, 1)}
      {:error, _} = err -> err
    end
  end

end
