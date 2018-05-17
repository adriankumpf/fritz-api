defmodule FritzApi.Commands.DeviceListInfosTest do
  use ExUnit.Case

  alias FritzApi.Commands.DeviceListInfos
  alias FritzApi.Actor

  test "parses devicelist xml if no properties are undefined" do
    xml = """
    <devicelist version="1">
      <device
        identifier="01234 0000123"
        id="51"
        functionbitmask="2944"
        fwversion="03.87"
        manufacturer="AVM"
        productname="FRITZ!DECT 200"
      >
        <present>1</present>
        <name>Smart Plug</name>
        <switch>
          <state>0</state>
          <mode>manuell</mode>
          <lock>0</lock>
          <devicelock>0</devicelock>
        </switch>
          <powermeter>
          <power>0</power>
          <energy>89418</energy>
        </powermeter>
        <temperature>
          <celsius>205</celsius>
          <offset>0</offset>
        </temperature>
      </device>
    </devicelist>
    """

    devicelist = DeviceListInfos.parse_device_list(xml)

    assert devicelist === [
             %Actor{
               ain: "012340000123",
               fwversion: "03.87",
               id: 51,
               manufacturer: "AVM",
               name: "Smart Plug",
               powermeter: %{energy: 89.418, power: 0.0},
               present: true,
               productname: "FRITZ!DECT 200",
               switch: %{devicelock: false, lock: false, mode: :manual, state: false},
               temperature: %{celsius: 20.5, offset: 0.0}
             }
           ]
  end

  test "parses devicelist xml if properties are undefined" do
    xml = """
    <devicelist version="1">
      <device
        identifier="01234 0000123"
        id="51"
        functionbitmask="2944"
        fwversion="03.87"
        manufacturer="AVM"
        productname="FRITZ!DECT 200"
      >
        <present></present>
        <name>Smart Plug</name>
        <switch>
          <state></state>
          <mode></mode>
          <lock></lock>
          <devicelock></devicelock>
        </switch>
        <powermeter>
          <power></power>
          <energy></energy>
        </powermeter>
        <temperature>
          <celsius></celsius>
          <offset></offset>
        </temperature>
      </device>
    </devicelist>
    """

    devicelist = DeviceListInfos.parse_device_list(xml)

    assert devicelist === [
             %Actor{
               ain: "012340000123",
               fwversion: "03.87",
               id: 51,
               manufacturer: "AVM",
               name: "Smart Plug",
               powermeter: %{energy: nil, power: nil},
               present: nil,
               productname: "FRITZ!DECT 200",
               switch: %{devicelock: nil, lock: nil, mode: nil, state: nil},
               temperature: %{celsius: nil, offset: nil}
             }
           ]
  end
end
