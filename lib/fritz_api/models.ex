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

  # Every helper below is total: the FritzBox leaves elements empty (`<lock />`,
  # which decodes to an empty map), and is free to grow values we don't know
  # yet. Both become `nil` rather than a crash mid-devicelist.

  def to_atom(str) do
    String.to_existing_atom(str)
  rescue
    ArgumentError -> str
  end

  def to_boolean("1"), do: true
  def to_boolean("0"), do: false
  def to_boolean(_value), do: nil

  def to_integer(str) when is_binary(str) do
    case Integer.parse(str) do
      {int, ""} -> int
      _ -> nil
    end
  end

  def to_integer(_value), do: nil

  # The FritzBox reports fixed-point decimals as integers, e.g. "89418" for
  # 89.418 kWh. `scale` is the divisor, e.g. `1000`. It differs per element, so
  # don't assume it matches the same quantity elsewhere in the API.
  def to_float(str, scale) when is_binary(str) do
    case to_integer(str) do
      nil -> nil
      int -> int / scale
    end
  end

  def to_float(_value, _scale), do: nil
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

  alias FritzApi.{Alert, Powermeter, Switch, Temperature}

  defstruct ~w(ain alert functions fwversion id manufacturer name
               powermeter present productname switch temperature)a

  @type t :: %__MODULE__{
          ain: String.t() | nil,
          alert: Alert.t() | nil,
          functions: [String.t()],
          fwversion: String.t() | nil,
          id: integer | nil,
          manufacturer: String.t() | nil,
          name: String.t() | nil,
          powermeter: Powermeter.t() | nil,
          present: boolean | nil,
          productname: String.t() | nil,
          switch: Switch.t() | nil,
          temperature: Temperature.t() | nil
        }

  @impl true
  def into(attrs) do
    # XML attributes arrive prefixed with "-"; child elements are nested under
    # "#content". Unknown keys survive `to_atom/1` as strings and `struct/2`
    # drops them.
    {content, attributes} = Map.pop(attrs, "#content")

    struct(__MODULE__, Enum.map(attributes, &attribute/1) ++ children(content))
  end

  defp attribute({"-functionbitmask", bitmask}), do: {:functions, parse_functions(bitmask)}
  defp attribute({"-identifier", ain}), do: {:ain, String.replace(ain, " ", "")}
  defp attribute({"-id", id}), do: {:id, to_integer(id)}
  defp attribute({key, value}), do: {to_atom(String.trim_leading(key, "-")), value}

  defp children(content) when is_map(content), do: Enum.map(content, &child/1)
  defp children(_content), do: []

  defp child({"temperature", attrs}), do: {:temperature, Temperature.into(attrs)}
  defp child({"powermeter", attrs}), do: {:powermeter, Powermeter.into(attrs)}
  defp child({"switch", attrs}), do: {:switch, Switch.into(attrs)}
  defp child({"alert", attrs}), do: {:alert, Alert.into(attrs)}
  defp child({"present", value}), do: {:present, to_boolean(value)}
  defp child({key, value}), do: {to_atom(key), value}

  # Bit positions of the device function classes within the `functionbitmask`
  # attribute, as documented by AVM. Unlisted bits are reserved.
  @functions [
    {0, "HAN-FUN Gerät"},
    {1, "AVM DECT Repeater"},
    {2, "Licht/Lampe"},
    {4, "Alarm-Sensor"},
    {5, "AVM-Button"},
    {6, "Heizkörperregler"},
    {7, "Energie Messgerät"},
    {8, "Temperatursensor"},
    {9, "Schaltsteckdose"},
    {11, "Mikrofon"},
    {13, "HAN-FUN-Unit"},
    {15, "an-/ausschaltbares Gerät/Steckdose/Lampe/Aktor"},
    {16, "Gerät mit einstellbarem Dimm-, Höhen- bzw. Niveau-Level"},
    {17, "Lampe mit einstellbarer Farbe/Farbtemperatur"}
  ]

  defp parse_functions(bitmask) do
    import Bitwise

    case to_integer(bitmask) do
      nil -> []
      n -> for {bit, function} <- @functions, (n >>> bit &&& 1) == 1, do: function
    end
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
          celsius: float | nil,
          offset: float | nil
        }

  defstruct [:celsius, :offset]

  @impl true
  def into(attrs) do
    %__MODULE__{
      celsius: to_float(attrs["celsius"], 10),
      offset: to_float(attrs["offset"], 10)
    }
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
          energy: float | nil,
          power: float | nil,
          voltage: float | nil
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
          devicelock: boolean | nil,
          state: boolean | nil,
          lock: boolean | nil,
          mode: :manual | :auto | nil
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
  def into(attrs) do
    %__MODULE__{
      state: to_boolean(attrs["state"]),
      last_alert_change: to_datetime(attrs["lastalertchgtimestamp"])
    }
  end

  defp to_datetime(ts) do
    with seconds when is_integer(seconds) <- to_integer(ts),
         {:ok, datetime} <- DateTime.from_unix(seconds) do
      datetime
    else
      _ -> nil
    end
  end
end
