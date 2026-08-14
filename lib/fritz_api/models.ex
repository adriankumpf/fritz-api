defmodule FritzApi.Model do
  @moduledoc false

  @callback into(map) :: struct

  defmacro __using__(_opts) do
    quote do
      @moduledoc section: :models

      @behaviour FritzApi.Model

      import FritzApi.Model
    end
  end

  def to_atom(str) do
    String.to_existing_atom(str)
  rescue
    ArgumentError -> str
  end

  def to_boolean("1"), do: true
  def to_boolean("0"), do: false
  def to_boolean(nil), do: nil
  def to_boolean(%{}), do: nil

  def to_integer(nil), do: nil
  def to_integer(%{}), do: nil

  def to_integer(str) do
    case Integer.parse(str) do
      {int, ""} -> int
      _ -> nil
    end
  end

  # The FritzBox reports fixed-point decimals as integers, e.g. "89418" for
  # 89.418 kWh. `scale` is the divisor, e.g. `1000`. It differs per element, so
  # don't assume it matches the same quantity elsewhere in the API.
  def to_float(nil, _scale), do: nil
  def to_float(%{}, _scale), do: nil

  def to_float(str, scale) do
    case to_integer(str) do
      nil -> nil
      int -> int / scale
    end
  end
end

defmodule FritzApi.Actor do
  @moduledoc """
  A smart home actor.

  ### Properties:

  - `ain`: identification of the actor, e.g. "012340000123" or MAC address for
  network devices
  - `fwversion`: firmware version of the device
  - `id`: internal device ID
  - `manufacturer`: should always be "AVM"
  - `productname`: product name of the device; `nil` if undefined or unknown
  - `present`: indicates whether the devices is connected with the FritzBox;
  either `true`, `false` or `nil`
  - `name`: name of the device
  - `functions`: list of device function classes

  """

  use FritzApi.Model

  alias FritzApi.{Temperature, Powermeter, Switch, Alert}

  defstruct ~w(ain alert functions fwversion id manufacturer name
               powermeter present productname switch temperature)a

  @type t :: %__MODULE__{
          ain: String.t(),
          alert: Alert.t(),
          functions: [String.t()],
          fwversion: String.t(),
          id: String.t(),
          manufacturer: String.t(),
          name: String.t(),
          powermeter: Powermeter.t(),
          present: boolean,
          productname: String.t(),
          switch: Switch.t(),
          temperature: Temperature.t()
        }

  @impl true
  def into(attrs) do
    fields =
      Enum.flat_map(attrs, fn
        {"#content", content} when is_map(content) ->
          Enum.map(content, fn
            {"temperature", attrs} -> {:temperature, Temperature.into(attrs)}
            {"powermeter", attrs} -> {:powermeter, Powermeter.into(attrs)}
            {"switch", attrs} -> {:switch, Switch.into(attrs)}
            {"alert", attrs} -> {:alert, Alert.into(attrs)}
            {"present", value} -> {:present, to_boolean(value)}
            {key, value} -> {to_atom(key), value}
          end)

        {"-functionbitmask", bitmask} ->
          [{:functions, parse_functions(bitmask)}]

        {"-identifier", ain} ->
          [{:ain, String.replace(ain, " ", "")}]

        {"-id", id} ->
          [{:id, to_integer(id)}]

        {"-" <> key, value} ->
          [{to_atom(key), value}]
      end)

    struct(__MODULE__, fields)
  end

  defp parse_functions(bitmask) do
    import Bitwise

    n = String.to_integer(bitmask)

    [i0, i1, i2, _i3, i4, i5, i6, i7, i8, i9, _i10, i11, _i12, i13, _i14, i15, i16, i17] =
      for i <- 0..17, do: n >>> i &&& 1

    [
      {"HAN-FUN Gerät", i0},
      {"Licht/Lampe", i2},
      {"Alarm-Sensor", i4},
      {"AVM- Button", i5},
      {"Heizkörperregler", i6},
      {"Energie Messgerät", i7},
      {"Temperatursensor", i8},
      {"Schaltsteckdose", i9},
      {"0AVM DECT Repeater", i1},
      {"Mikrofon", i11},
      {"HAN-FUN-Unit", i13},
      {"an-/ausschaltbares Gerät/Steckdose/Lampe/Aktor", i15},
      {"Gerät mit einstellbarem Dimm-, Höhen- bzw. Niveau-Level", i16},
      {"Lampe mit einstellbarer Farbe/Farbtemperatur", i17}
    ]
    |> Enum.filter(fn {_, i} -> i == 1 end)
    |> Enum.map(fn {function, _} -> function end)
  end
end

defmodule FritzApi.Temperature do
  @moduledoc """
  A temperature sensor

  ### Properties:

  - `celsius`: last measured temperature
  - `offset`: configured offset value

  """

  use FritzApi.Model

  @type t :: %__MODULE__{
          celsius: float,
          offset: float
        }

  defstruct [:celsius, :offset]

  @impl true
  def into(%{"celsius" => celsius, "offset" => offset}) do
    %__MODULE__{celsius: to_float(celsius, 10), offset: to_float(offset, 10)}
  end
end

defmodule FritzApi.Powermeter do
  @moduledoc """
  A power meter

  ### Properties

  - `power`: current power consumption (Watts); gets updated roughly every 2
  minutes
  - `energy`: total energy usage (kWh) since first use
  - `voltage`: current voltage (V); gets updated roughly every 2 minutes

  """
  use FritzApi.Model

  @type t :: %__MODULE__{
          energy: float,
          power: float,
          voltage: float
        }

  defstruct [:energy, :power, :voltage]

  @impl true
  def into(attrs) do
    %__MODULE__{
      energy: to_float(attrs["energy"], 1000),
      power: to_float(attrs["power"], 100),
      voltage: to_float(attrs["voltage"], 1000)
    }
  end
end

defmodule FritzApi.Switch do
  @moduledoc """
  A Switch

  ### Properties

  - `state`: switching state; either `true`, `false` or `nil`
  - `mode`: `:auto` if in timer switch mode, otherwise `:manual`; can also be
  `nil` if undefined / unknown
  - `lock`: state of the shift lock (via UI/API); either `true`, `false` or `nil`
  - `devicelock`: state of the shift lock (via hardware button); either `true`,
  `false` or `nil`

  """

  use FritzApi.Model

  @type t :: %__MODULE__{
          mode: :manual | :auto,
          devicelock: boolean,
          state: boolean,
          lock: boolean
        }

  defstruct [:devicelock, :state, :lock, :mode]

  @impl true
  def into(attrs) do
    fields =
      Enum.map(attrs, fn
        {"mode", "manuell"} -> {:mode, :manual}
        {"mode", "auto"} -> {:mode, :auto}
        {key, val} -> {to_atom(key), to_boolean(val)}
      end)

    struct(__MODULE__, fields)
  end
end

defmodule FritzApi.Alert do
  @moduledoc """
  An alert sensor

  ### Properties

  - `state`: last known alert state; either `true`, `false` or `nil`
  - `last_alert_change`: time of the last alert change

  """
  use FritzApi.Model

  @type t :: %__MODULE__{
          state: boolean | nil,
          last_alert_change: DateTime.t() | nil
        }

  defstruct [:state, :last_alert_change]

  @impl true
  def into(%{"state" => state, "lastalertchgtimestamp" => ts}) do
    %__MODULE__{state: to_boolean(state), last_alert_change: to_datetime(ts)}
  end

  defp to_datetime(ts) do
    with true <- is_binary(ts),
         {seconds, ""} <- Integer.parse(ts),
         {:ok, dt} <- DateTime.from_unix(seconds, :second) do
      dt
    else
      _ -> nil
    end
  end
end
