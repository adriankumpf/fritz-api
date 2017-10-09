defmodule FritzApi.Commands do
  @moduledoc false

  alias FritzApi.Commands.{Helper, DeviceListInfos}
  alias FritzApi.{FritzBox, Actor}

  @path "/webservices/homeautoswitch.lua"

  @type opts :: [base: String.t, ssl: list]

  @spec get_device_list_infos(String.t, opts) :: {:error, any} | {:ok, [Actor.t]}
  def get_device_list_infos(sid, opts) do
    "getdevicelistinfos"
    |> execute_command(sid, opts)
    |> to_devicelist
  end

  @spec get_switch_list(String.t, opts) :: {:error, any} | {:ok, [String.t]}
  def get_switch_list(sid, opts) do
    "getswitchlist"
    |> execute_command(sid, opts)
    |> to_list
  end

  @spec set_switch_on(String.t, String.t, opts) :: {:error, any} | :ok
  def set_switch_on(sid, ain, opts) do
    "setswitchon"
    |> execute_command(sid, [ain: ain], opts)
    |> to_ok
  end

  @spec set_switch_off(String.t, String.t, opts) :: {:error, any} | :ok
  def set_switch_off(sid, ain, opts) do
    "setswitchoff"
    |> execute_command(sid, [ain: ain], opts)
    |> to_ok
  end

  @spec set_switch_toggle(String.t, String.t, opts) :: {:error, any} | {:ok, nil | boolean}
  def set_switch_toggle(sid, ain, opts) do
    "setswitchtoggle"
    |> execute_command(sid, [ain: ain], opts)
    |> to_boolean
  end

  @spec get_switch_state(String.t, String.t, opts) :: {:error, any} | {:ok, nil | boolean}
  def get_switch_state(sid, ain, opts) do
    "getswitchstate"
    |> execute_command(sid, [ain: ain], opts)
    |> to_boolean
  end

  @spec get_switch_present(String.t, String.t, opts) :: {:error, any} | {:ok, nil | boolean}
  def get_switch_present(sid, ain, opts) do
    "getswitchpresent"
    |> execute_command(sid, [ain: ain], opts)
    |> to_boolean
  end

  @spec get_switch_power(String.t, String.t, opts) :: {:error, any} | {:ok, nil | float}
  def get_switch_power(sid, ain, opts) do
    "getswitchpower"
    |> execute_command(sid, [ain: ain], opts)
    |> to_float(3)
  end

  @spec get_switch_energy(String.t, String.t, opts) :: {:error, any} | {:ok, nil | float}
  def get_switch_energy(sid, ain, opts) do
    "getswitchenergy"
    |> execute_command(sid, [ain: ain], opts)
    |> to_float(3)
  end

  @spec get_switch_name(String.t, String.t, opts) :: {:error, any} | {:ok, String.t}
  def get_switch_name(sid, ain, opts) do
    "getswitchname"
    |> execute_command(sid, [ain: ain], opts)
  end

  @spec get_temperature(String.t, String.t, opts) :: {:error, any} | {:ok, nil | float}
  def get_temperature(sid, ain, opts) do
    "gettemperature"
    |> execute_command(sid, [ain: ain], opts)
    |> to_float(1)
  end

  # Private

  @spec execute_command(String.t, String.t, [ain: String.t], opts) :: {:error, any} | {:ok, String.t}
  defp execute_command(cmd, sid, [ain: ain], opts) do
    FritzBox.get(@path, [switchcmd: cmd, sid: sid, ain: ain], opts)
    |> translate_actor_error
  end
  @spec execute_command(String.t, String.t, opts) :: {:error, any} | {:ok, String.t}
  defp execute_command(cmd, sid, opts) do
    FritzBox.get(@path, [switchcmd: cmd, sid: sid], opts)
  end

  @spec translate_actor_error({:error, any} | {:ok, String.t}) :: {:error, any} | {:ok, String.t}
  defp translate_actor_error({:error, :bad_request}), do:
    {:error, :actor_not_found}
  defp translate_actor_error(other), do:
    other

  @spec to_devicelist({:ok, String.t} | {:error, any}) :: {:ok, [Actor.t]} | {:error, any}
  defp to_devicelist({:ok, xml}), do: {:ok, DeviceListInfos.parse_device_list(xml)}
  defp to_devicelist({:error, _} = err), do: err

  @spec to_list({:ok, String.t} | {:error, any}) :: {:ok, [String.t]} | {:error, any}
  defp to_list({:ok, string}), do: {:ok, Helper.parse_list(string)}
  defp to_list({:error, _} = err), do: err

  @spec to_ok({:ok, String.t} | {:error, any}) :: :ok | {:error, any}
  defp to_ok({:ok, "1"}), do: :ok
  defp to_ok({:ok, "0"}), do: :ok
  defp to_ok({:error, _} = err), do: err

  @spec to_boolean({:ok, String.t} | {:error, any}) :: {:ok, boolean | nil} | {:error, any}
  defp to_boolean({:ok, val}), do: {:ok, Helper.parse_boolean(val)}
  defp to_boolean({:error, _} = err), do: err

  @spec to_float({:ok, String.t} | {:error, any}, integer) :: {:ok, float | nil} | {:error, any}
  defp to_float({:ok, val}, dec_places), do: {:ok, Helper.parse_float(val, dec_places)}
  defp to_float({:error, _} = err, _), do: err

end
