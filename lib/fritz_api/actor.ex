defmodule FritzApi.Actor do
  @moduledoc """
  A smart home actor.

  ## Properties:

  - ain: identification of the actor, e.g. "012340000123" or MAC address for network devices
  - fwversion: firmware version of the device
  - id: interal device ID
  - manufacturer: should always be "AVM"
  - productname: product name of the device; `nil` if undefined / unknown
  - present: indicates whether the devices is connected with the FritzBox; either [`true` | `false` | `nil`]
  - name: name of the device

  ### Optional Properties

  Depending on the device type different properties can be available.

  #### Switch

  - state: switching state; either [`true` | `false` | `nil`]
  - mode: `:auto` if in timer switch mode, otherwise `:manual`; can also be `nil` if undefined / unknown
  - lock: state of the shift lock (via UI/API); either [`true` | `false` | `nil`]
  - devicelock: state of the shift lock (via hardware button); either [`true` | `false` | `nil`]

  #### Powermeter

  - power: current power consumption (Watts); gets updated roughly every 2 minutes
  - energy: total energy usage (kWh) since first use

  #### Temperature

  - celsius: last measured temperature
  - offsset: configured offsset value

  ### Alert

  - state: last known alert state; either [`true` | `false` | `nil`]

  # Hkr (Thermostat)

  Not yet implemented.

  """

  defstruct [:fwversion, :id, :ain, :manufacturer, :productname, :present,
             :name, :switch, :powermeter, :temperature, :alert]

  @type t :: %__MODULE__{
    fwversion: String.t,
    id: integer,
    ain: String.t,
    manufacturer: String.t,
    productname: String.t,
    present: boolean,
    name: String.t,
    switch: (none | [%{
      state: boolean,
      mode: String.t,
      lock: boolean,
      devicelock: boolean
    }]),
    powermeter: (none | [%{
      power: float,
      energy: float
    }]),
    temperature: (none | [%{
      celsius: float,
      offset: float
    }]),
    alert: (none | [%{
      state: boolean
    }])
  }

end
