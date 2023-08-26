defmodule FritzApi do
  @moduledoc """
  A Fritz!Box Home Automation API Client for Elixir.

  ## Usage

      iex> {:ok, client} = FritzApi.Client.new()
      ...>                 |> FritzApi.Client.login("admin", "changeme")

      iex> FritzApi.set_switch_off(client, "687690315761")
      :ok

      iex> FritzApi.get_temperature(client, "687690315761")
      {:ok, 23.5}

  ## Configuration

  The main way to configure FritzApi is through the options passed to `FritzApi.Client.new/1`.

  To customize the behaviour of the HTTP client used by FritzApi, you can configure FritzApi through
  the application environment . For example, you can do this in `config/runtime.exs`:

      # config/runtime.exs
      config :fritz_api,
        # ...

  You can use these options:

  - `:client` (`t:module/0`) - A module that implements the `FritzApi.HTTPClient`
  behaviour. Defaults to `FritzApi.HTTPClient.Finch` (requires `:finch`).

  - `:client_pool_opts` (`t:keyword/0`) - Options to configure the HTTP client pool. See
  `Finch.start_link/1`. Defaults to `[]`.

  - `:client_request_opts` (`t:keyword/0`) - Options passed to the `c:FritzApi.HTTPClient.get/2`
  callback. See `Finch.request/3`. Defaults to `[]`.
  """

  alias FritzApi.{Client, Error, Actor}

  @typedoc """
  Name of the FritzBox user.

  > #### Note {: .info}
  >
  > With FRITZ! OS 7.24 and later, the user name cannot be empty.
  """
  @type useranme :: String.t()

  @typedoc "Password of the FritzBox user."
  @type password :: String.t()

  @typedoc "Unique actor identifier."
  @type ain :: String.t()

  @doc """
  Get essential information of all smart home devices.

  ## Example

      iex> FritzApi.get_device_list_infos(client)
      {:ok, [%FritzApi.Actor{
         ain: "687690315761",
         alert: nil,
         functions: ["Energie Messgerät", "Temperatursensor",
           "Schaltsteckdose", "Mikrofon"],
         fwversion: "04.17",
         id: "1",
         manufacturer: "AVM",
         name: "Aussensteckdose",
         powermeter: %FritzApi.Powermeter{
           energy: 8.94,
           power: 0.0,
           voltage: 231.17
         },
         present: true,
         productname: "FRITZ!DECT 210",
         switch: %FritzApi.Switch{
           devicelock: false,
           lock: false,
           mode: :auto,
           state: false
         },
         temperature: %FritzApi.Temperature{
           celsius: 21.0,
           offset: 0.0
         }
       }]}

  """
  @spec get_device_list_infos(Client.t()) :: {:error, Error.t()} | {:ok, [Actor.t()]}
  def get_device_list_infos(%Client{} = client) do
    case Client.execute_command(client, "getdevicelistinfos") do
      {:ok, %{"devicelist" => %{"#content" => %{"device" => devices}}}} when is_list(devices) ->
        {:ok, Enum.map(devices, &Actor.into/1)}

      {:ok, %{"devicelist" => %{"#content" => %{"device" => device}}}} when is_map(device) ->
        {:ok, [Actor.into(device)]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get the actuator identification numbers (AIN) of all known actors.

  ## Example

      iex> FritzApi.get_switch_list(client)
      {:ok, ["687690315761"]}

  """
  @spec get_switch_list(Client.t()) :: {:error, Error.t()} | {:ok, [ain]}
  def get_switch_list(%Client{} = client) do
    case Client.execute_command(client, "getswitchlist") do
      {:ok, ains} when is_binary(ains) ->
        {:ok, ains |> String.trim_trailing() |> String.split(",")}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Turn on the switch.

  ## Example

      iex> FritzApi.set_switch_on(client, "687690315761")
      :ok

  """
  @spec set_switch_on(Client.t(), ain) :: {:error, Error.t()} | :ok
  def set_switch_on(%Client{} = client, ain) do
    case Client.execute_command(client, "setswitchon", ain: ain) do
      {:ok, "1"} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Turn off the switch.

  ## Example

      iex> FritzApi.set_switch_off(client, "687690315761")
      :ok

  """
  @spec set_switch_off(Client.t(), ain) :: {:error, Error.t()} | :ok
  def set_switch_off(%Client{} = client, ain) do
    case Client.execute_command(client, "setswitchoff", ain: ain) do
      {:ok, "0"} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Toggle the switch.

  ## Example

      iex> FritzApi.set_switch_toggle(client, "687690315761")
      {:ok, :off}

  """
  @spec set_switch_toggle(Client.t(), ain) :: {:error, Error.t()} | {:ok, :on | :off}
  def set_switch_toggle(%Client{} = client, ain) do
    case Client.execute_command(client, "setswitchtoggle", ain: ain) do
      {:ok, "1"} -> {:ok, :on}
      {:ok, "0"} -> {:ok, :off}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get the current switching state.

  Returns `{:ok, :unknown}` if the state is unknown.

  ## Example

      iex> FritzApi.get_switch_state(client, "687690315761")
      {:ok, :on}

  """
  @spec get_switch_state(Client.t(), ain) :: {:error, Error.t()} | {:ok, :unknown | :on | :off}
  def get_switch_state(%Client{} = client, ain) do
    case Client.execute_command(client, "getswitchstate", ain: ain) do
      {:ok, "1"} -> {:ok, :on}
      {:ok, "0"} -> {:ok, :off}
      {:ok, "inval"} -> {:ok, :unknown}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get the current connection state of the actor.

  ## Example

      iex> FritzApi.get_switch_present(client, "687690315761")
      {:ok, true}

  """
  @spec get_switch_present(Client.t(), ain) :: {:error, Error.t()} | {:ok, boolean}
  def get_switch_present(%Client{} = client, ain) do
    case Client.execute_command(client, "getswitchpresent", ain: ain) do
      {:ok, "1"} -> {:ok, true}
      {:ok, "0"} -> {:ok, false}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get the current power consumption (Watt) of the switch.

  Returns `{:ok, :unknown}` if the state is unknown.

  ## Example

      iex> FritzApi.get_switch_power(client, "687690315761")
      {:ok, 0.0}

  """
  @spec get_switch_power(Client.t(), ain) :: {:error, Error.t()} | {:ok, :unknown | float}
  def get_switch_power(%Client{} = client, ain) do
    case Client.execute_command(client, "getswitchpower", ain: ain) do
      {:ok, "inval"} -> {:ok, :unknown}
      {:ok, power} when is_binary(power) -> {:ok, to_float(power, 3)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get the total energy usage (kWh) of the switch.

  Returns `{:ok, :unknown}` if the state is unknown.

  ## Example

      iex> FritzApi.get_switch_energy(client, "687690315761")
      {:ok, 0.475}

  """
  @spec get_switch_energy(Client.t(), ain) :: {:error, Error.t()} | {:ok, :unknown | float}
  def get_switch_energy(%Client{} = client, ain) do
    case Client.execute_command(client, "getswitchenergy", ain: ain) do
      {:ok, "inval"} -> {:ok, :unknown}
      {:ok, energy} when is_binary(energy) -> {:ok, to_float(energy, 3)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get the name of the actor.

  ## Example

      iex> FritzApi.get_switch_name(client, "687690315761")
      {:ok, "FRITZ!DECT #1"}

  """
  @spec get_switch_name(Client.t(), ain) :: {:error, Error.t()} | {:ok, String.t()}
  def get_switch_name(%Client{} = client, ain) do
    Client.execute_command(client, "getswitchname", ain: ain)
  end

  @doc """
  Get the last measured temperature (Celsius) of the actor.

  Returns `{:ok, :unknown}` if the temperature could not be measured.

  ## Example

      iex> FritzApi.get_temperature(client, "687690315761")
      {:ok, 23.5}

  """
  @spec get_temperature(Client.t(), ain) :: {:error, Error.t()} | {:ok, :unknown | float}
  def get_temperature(%Client{} = client, ain) do
    case Client.execute_command(client, "gettemperature", ain: ain) do
      {:ok, "inval"} -> {:ok, :unknown}
      {:ok, temp} when is_binary(temp) -> {:ok, to_float(temp, 1)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get the target temperature (Celsius) currently set for the radiator
  controller.

  ## Example

      iex> FritzApi.get_hkr_target_temperature(client, "687690315761")
      {:ok, 23.5}

  """
  @spec get_hkr_target_temperature(Client.t(), ain) ::
          {:error, Error.t()} | {:ok, :unknown | :on | :off | float}
  def get_hkr_target_temperature(%Client{} = client, ain) do
    case Client.execute_command(client, "gethkrtsoll", ain: ain) do
      {:ok, value} when is_binary(value) -> {:ok, from_hkr_temp(value)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get the comfort temperature (Celsius) set for time switching of the radiator
  controller.

  ## Example

      iex> FritzApi.get_hkr_comfort_temperature(client, "687690315761")
      {:ok, 23.5}

  """
  @spec get_hkr_comfort_temperature(Client.t(), ain) ::
          {:error, Error.t()} | {:ok, :unknown | :on | :off | float}
  def get_hkr_comfort_temperature(%Client{} = client, ain) do
    case Client.execute_command(client, "gethkrkomfort", ain: ain) do
      {:ok, value} when is_binary(value) -> {:ok, from_hkr_temp(value)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get the economy temperature (Celsius) set for time switching of the radiator
  controller.

  ## Example

      iex> FritzApi.get_hkr_economy_temperature(client, "687690315761")
      {:ok, 23.5}

  """
  @spec get_hkr_economy_temperature(Client.t(), ain) ::
          {:error, Error.t()} | {:ok, :unknown | :on | :off | float}
  def get_hkr_economy_temperature(%Client{} = client, ain) do
    case Client.execute_command(client, "gethkrabsenk", ain: ain) do
      {:ok, value} when is_binary(value) -> {:ok, from_hkr_temp(value)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Set the target temperature (Celsius) of the radiator controller.

  ## Example

      iex> FritzApi.set_hkr_target_temperature(client, "687690315761", 21.5)
      {:ok, 23.5}

  """
  @spec set_hkr_target_temperature(Client.t(), ain, 8..28) :: {:error, Error.t()} | :ok
  def set_hkr_target_temperature(%Client{} = client, ain, temp)
      when is_number(temp) and (temp >= 8.0 and temp <= 28.0) do
    case Client.execute_command(client, "sethkrtsoll", ain: ain, param: to_hkr_temp(temp)) do
      {:ok, _unknown_response} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Enabele the target temperature of the radiator controller.

  ## Example

      iex> FritzApi.enable_hkr_target_temperature(client, "687690315761")
      {:ok, 23.5}

  """
  @spec enable_hkr_target_temperature(Client.t(), ain) :: {:error, Error.t()} | :ok
  def enable_hkr_target_temperature(%Client{} = client, ain) do
    case Client.execute_command(client, "sethkrtsoll", ain: ain, param: 254) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Disable the target temperature of the radiator controller.

  ## Example

      iex> FritzApi.disable_hkr_target_temperature(client, "687690315761")
      {:ok, 23.5}

  """
  @spec disable_hkr_target_temperature(Client.t(), ain) :: {:error, Error.t()} | :ok
  def disable_hkr_target_temperature(%Client{} = client, ain) do
    case Client.execute_command(client, "sethkrtsoll", ain: ain, param: 253) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp to_float(value, dec_places)
       when is_binary(value) and is_number(dec_places) and dec_places > 0 do
    {int, ""} = Integer.parse(value)
    int / :math.pow(10, dec_places)
  end

  defp from_hkr_temp(value) when is_binary(value) do
    case Integer.parse(value) do
      {253, ""} -> :off
      {254, ""} -> :on
      {int, ""} when int in 16..56 -> int / 2
    end
  end

  defp to_hkr_temp(temp) when is_number(temp) do
    round(temp * 2) |> min(56) |> max(16)
  end
end
