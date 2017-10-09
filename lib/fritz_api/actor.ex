defmodule FritzApi.Actor do
  @moduledoc """
  A smart home actor.

  ## Properties:

  - __ain__: identification of the actor, e.g. "012340000123" or MAC address for network devices
  - __fwversion__: firmware version of the device
  - __id__: interal device ID
  - __manufacturer__: should always be "AVM"
  - __productname__: product name of the device; `nil` if undefined / unknown
  - __present__: indicates whether the devices is connected with the FritzBox; either [`true` | `false` | `nil`]
  - __name__: name of the device

  ### Optional Properties

  Depending on the device type different properties can be available.

  #### Switch

  - __state__: switching state; either [`true` | `false` | `nil`]
  - __mode__: `:auto` if in timer switch mode, otherwise `:manual`; can also be `nil` if undefined / unknown
  - __lock__: state of the shift lock (via UI/API); either [`true` | `false` | `nil`]
  - __devicelock__: state of the shift lock (via hardware button); either [`true` | `false` | `nil`]

  #### Powermeter

  - __power__: current power consumption (Watts); gets updated roughly every 2 minutes
  - __energy__: total energy usage (kWh) since first use

  #### Temperature

  - __celsius__: last measured temperature
  - __offsset__: configured offsset value

  #### Alert

  - __state__: last known alert state; either [`true` | `false` | `nil`]

  #### Hkr (Thermostat)

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
    name: String.t,
    present: boolean | nil,
    switch: (none | [%{
      state: boolean | nil,
      mode: String.t | nil,
      lock: boolean | nil,
      devicelock: boolean | nil,
    }]),
    powermeter: (none | [%{
      power: float | nil,
      energy: float| nil,
    }]),
    temperature: (none | [%{
      celsius: float | nil,
      offset: float |nil,
    }]),
    alert: (none | [%{
      state: boolean | nil,
    }])
  }

end
