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

  To customize the behaviour of the HTTP client used by FritzApi, you can configure FritzApi
  through the application environment. For example, you can do this in `config/runtime.exs`:

      # config/runtime.exs
      config :fritz_api,
        client: FritzApi.HTTPClient.Finch,
        client_pool_opts: [size: 10],
        client_request_opts: [receive_timeout: 10_000]

  You can use these options:

  - `:client` (`t:module/0`) - A module that implements the `FritzApi.HTTPClient`
  behaviour. Defaults to `FritzApi.HTTPClient.Finch` (requires `:finch`).

  - `:client_pool_opts` (`t:keyword/0`) - Options to configure the HTTP client pool. See
  `Finch.start_link/1`. Defaults to `[]`.

  - `:client_request_opts` (`t:keyword/0`) - Options passed to the `c:FritzApi.HTTPClient.get/2`
  callback. See `Finch.request/3`. Defaults to `[]`.
  """

  alias FritzApi.{Actor, Client, Error}

  @typedoc """
  Name of the FritzBox user.

  > #### Note {: .info}
  >
  > With FRITZ! OS 7.24 and later, the user name cannot be empty.
  """
  @type username :: String.t()

  @typedoc "Password of the FritzBox user."
  @type password :: String.t()

  @typedoc "Unique actor identifier."
  @type ain :: String.t()

  @typedoc "The result of a command that returns a value."
  @type result(value) :: {:ok, value} | {:error, Error.t()}

  @typedoc "The result of a command that returns no value."
  @type result :: :ok | {:error, Error.t()}

  @typedoc "Temperature (Celsius) of a radiator controller, or its on/off state."
  @type hkr_temperature :: :on | :off | float

  defguardp is_ain(ain) when is_binary(ain) and ain != ""

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
         id: 1,
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
  @spec get_device_list_infos(Client.t()) :: result([Actor.t()])
  def get_device_list_infos(%Client{} = client) do
    command(client, "getdevicelistinfos", fn
      %{"devicelist" => %{"#content" => %{"device" => devices}}} ->
        {:ok, Enum.map(List.wrap(devices), &Actor.into/1)}

      %{"devicelist" => _no_devices} ->
        {:ok, []}

      _ ->
        :error
    end)
  end

  @doc """
  Get the actuator identification numbers (AIN) of all known actors.

  ## Example

      iex> FritzApi.get_switch_list(client)
      {:ok, ["687690315761"]}

  """
  @spec get_switch_list(Client.t()) :: result([ain])
  def get_switch_list(%Client{} = client) do
    command(client, "getswitchlist", fn
      ains when is_binary(ains) ->
        case String.trim(ains) do
          "" -> {:ok, []}
          ains -> {:ok, String.split(ains, ",")}
        end

      _ ->
        :error
    end)
  end

  @doc """
  Turn on the switch.

  ## Example

      iex> FritzApi.set_switch_on(client, "687690315761")
      :ok

  """
  @spec set_switch_on(Client.t(), ain) :: result
  def set_switch_on(%Client{} = client, ain) when is_ain(ain) do
    command(client, "setswitchon", [ain: ain], %{"1" => :ok})
  end

  @doc """
  Turn off the switch.

  ## Example

      iex> FritzApi.set_switch_off(client, "687690315761")
      :ok

  """
  @spec set_switch_off(Client.t(), ain) :: result
  def set_switch_off(%Client{} = client, ain) when is_ain(ain) do
    command(client, "setswitchoff", [ain: ain], %{"0" => :ok})
  end

  @doc """
  Toggle the switch.

  ## Example

      iex> FritzApi.set_switch_toggle(client, "687690315761")
      {:ok, :off}

  """
  @spec set_switch_toggle(Client.t(), ain) :: result(:on | :off)
  def set_switch_toggle(%Client{} = client, ain) when is_ain(ain) do
    command(client, "setswitchtoggle", [ain: ain], %{"1" => {:ok, :on}, "0" => {:ok, :off}})
  end

  @doc """
  Get the current switching state.

  Returns `{:ok, :unknown}` if the state is unknown.

  ## Example

      iex> FritzApi.get_switch_state(client, "687690315761")
      {:ok, :on}

  """
  @spec get_switch_state(Client.t(), ain) :: result(:unknown | :on | :off)
  def get_switch_state(%Client{} = client, ain) when is_ain(ain) do
    command(client, "getswitchstate", [ain: ain], %{
      "1" => {:ok, :on},
      "0" => {:ok, :off},
      "inval" => {:ok, :unknown}
    })
  end

  @doc """
  Get the current connection state of the actor.

  ## Example

      iex> FritzApi.get_switch_present(client, "687690315761")
      {:ok, true}

  """
  @spec get_switch_present(Client.t(), ain) :: result(boolean)
  def get_switch_present(%Client{} = client, ain) when is_ain(ain) do
    command(client, "getswitchpresent", [ain: ain], %{"1" => {:ok, true}, "0" => {:ok, false}})
  end

  @doc """
  Get the current power consumption (Watt) of the switch.

  Returns `{:ok, :unknown}` if the state is unknown.

  ## Example

      iex> FritzApi.get_switch_power(client, "687690315761")
      {:ok, 0.0}

  """
  @spec get_switch_power(Client.t(), ain) :: result(:unknown | float)
  def get_switch_power(%Client{} = client, ain) when is_ain(ain) do
    command(client, "getswitchpower", [ain: ain], &to_float(&1, 1000))
  end

  @doc """
  Get the total energy usage (kWh) of the switch.

  Returns `{:ok, :unknown}` if the state is unknown.

  ## Example

      iex> FritzApi.get_switch_energy(client, "687690315761")
      {:ok, 0.475}

  """
  @spec get_switch_energy(Client.t(), ain) :: result(:unknown | float)
  def get_switch_energy(%Client{} = client, ain) when is_ain(ain) do
    command(client, "getswitchenergy", [ain: ain], &to_float(&1, 1000))
  end

  @doc """
  Get the name of the actor.

  ## Example

      iex> FritzApi.get_switch_name(client, "687690315761")
      {:ok, "FRITZ!DECT #1"}

  """
  @spec get_switch_name(Client.t(), ain) :: result(String.t())
  def get_switch_name(%Client{} = client, ain) when is_ain(ain) do
    command(client, "getswitchname", [ain: ain], fn
      name when is_binary(name) -> {:ok, name}
      _ -> :error
    end)
  end

  @doc """
  Get the last measured temperature (Celsius) of the actor.

  Returns `{:ok, :unknown}` if the temperature could not be measured.

  ## Example

      iex> FritzApi.get_temperature(client, "687690315761")
      {:ok, 23.5}

  """
  @spec get_temperature(Client.t(), ain) :: result(:unknown | float)
  def get_temperature(%Client{} = client, ain) when is_ain(ain) do
    command(client, "gettemperature", [ain: ain], &to_float(&1, 10))
  end

  @doc """
  Get the target temperature (Celsius) currently set for the radiator
  controller.

  ## Example

      iex> FritzApi.get_hkr_target_temperature(client, "687690315761")
      {:ok, 23.5}

  """
  @spec get_hkr_target_temperature(Client.t(), ain) :: result(hkr_temperature)
  def get_hkr_target_temperature(%Client{} = client, ain) when is_ain(ain) do
    command(client, "gethkrtsoll", [ain: ain], &to_hkr_temperature/1)
  end

  @doc """
  Get the comfort temperature (Celsius) set for time switching of the radiator
  controller.

  ## Example

      iex> FritzApi.get_hkr_comfort_temperature(client, "687690315761")
      {:ok, 23.5}

  """
  @spec get_hkr_comfort_temperature(Client.t(), ain) :: result(hkr_temperature)
  def get_hkr_comfort_temperature(%Client{} = client, ain) when is_ain(ain) do
    command(client, "gethkrkomfort", [ain: ain], &to_hkr_temperature/1)
  end

  @doc """
  Get the economy temperature (Celsius) set for time switching of the radiator
  controller.

  ## Example

      iex> FritzApi.get_hkr_economy_temperature(client, "687690315761")
      {:ok, 23.5}

  """
  @spec get_hkr_economy_temperature(Client.t(), ain) :: result(hkr_temperature)
  def get_hkr_economy_temperature(%Client{} = client, ain) when is_ain(ain) do
    command(client, "gethkrabsenk", [ain: ain], &to_hkr_temperature/1)
  end

  @doc """
  Set the target temperature (Celsius) of the radiator controller.

  The temperature is rounded to the nearest half degree and must be between
  `8.0` and `28.0`.

  ## Example

      iex> FritzApi.set_hkr_target_temperature(client, "687690315761", 21.5)
      :ok

  """
  @spec set_hkr_target_temperature(Client.t(), ain, number) :: result
  def set_hkr_target_temperature(%Client{} = client, ain, temp)
      when is_ain(ain) and is_number(temp) and temp >= 8 and temp <= 28 do
    set_hkr_target(client, ain, round(temp * 2))
  end

  @doc """
  Enable the target temperature of the radiator controller.

  ## Example

      iex> FritzApi.enable_hkr_target_temperature(client, "687690315761")
      :ok

  """
  @spec enable_hkr_target_temperature(Client.t(), ain) :: result
  def enable_hkr_target_temperature(%Client{} = client, ain) when is_ain(ain) do
    set_hkr_target(client, ain, 254)
  end

  @doc """
  Disable the target temperature of the radiator controller.

  ## Example

      iex> FritzApi.disable_hkr_target_temperature(client, "687690315761")
      :ok

  """
  @spec disable_hkr_target_temperature(Client.t(), ain) :: result
  def disable_hkr_target_temperature(%Client{} = client, ain) when is_ain(ain) do
    set_hkr_target(client, ain, 253)
  end

  defp set_hkr_target(client, ain, param) do
    command(client, "sethkrtsoll", [ain: ain, param: param], fn _echoed_param -> :ok end)
  end

  defp command(client, cmd, decoder), do: command(client, cmd, [], decoder)

  defp command(client, cmd, params, decoder) do
    with {:ok, body} <- Client.execute_command(client, cmd, params) do
      decode(body, decoder)
    end
  end

  # Since the FritzBox is free to grow new response values, unrecognized bodies
  # become an error rather than a crash.
  defp decode(body, table) when is_map(table), do: decode(body, &Map.get(table, &1, :error))

  defp decode(body, fun) when is_function(fun, 1) do
    case fun.(body) do
      :error -> {:error, %Error{reason: {:unexpected_response, body}}}
      result -> result
    end
  end

  # The FritzBox reports fixed-point decimals as integers, e.g. "89418" for
  # 89.418 kWh, and "inval" when the value could not be measured.
  defp to_float("inval", _scale), do: {:ok, :unknown}

  defp to_float(value, scale) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> {:ok, int / scale}
      _ -> :error
    end
  end

  defp to_float(_value, _scale), do: :error

  # Radiator controllers encode the temperature in half degrees, with 253 and
  # 254 reserved for "off" and "on".
  defp to_hkr_temperature(value) when is_binary(value) do
    case Integer.parse(value) do
      {253, ""} -> {:ok, :off}
      {254, ""} -> {:ok, :on}
      {int, ""} when int in 16..56 -> {:ok, int / 2}
      _ -> :error
    end
  end

  defp to_hkr_temperature(_value), do: :error
end
