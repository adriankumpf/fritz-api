defmodule FritzApi.Commands.DeviceListInfosTest do
  use FritzApi.Case, async: true

  describe "get_device_list_infos/1" do
    alias FritzApi.{Actor, Switch, Powermeter, Temperature}

    @tag logged_in: true
    test "returns one actor if the devicelist contains one device", %{client: client} do
      mock(fn
        %Tesla.Env{
          method: :get,
          url: "http://fritz.box/webservices/homeautoswitch.lua",
          query: [switchcmd: "getdevicelistinfos", sid: "$session_id"]
        } ->
          """
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
          |> text(headers: [{"content-type", "text/xml"}])
      end)

      assert {:ok, [actor]} = FritzApi.get_device_list_infos(client)

      assert actor == %Actor{
               id: 51,
               ain: "012340000123",
               productname: "FRITZ!DECT 200",
               manufacturer: "AVM",
               functions: ["Energie Messgerät", "Temperatursensor", "Schaltsteckdose", "Mikrofon"],
               fwversion: "03.87",
               name: "Smart Plug",
               present: true,
               alert: nil,
               powermeter: %Powermeter{energy: 89.418, power: 0.0, voltage: nil},
               switch: %Switch{devicelock: false, lock: false, mode: :manual, state: false},
               temperature: %Temperature{celsius: 20.5, offset: 0.0}
             }
    end

    @tag logged_in: true
    test "returns actors", %{client: client} do
      mock(fn
        %Tesla.Env{
          method: :get,
          url: "http://fritz.box/webservices/homeautoswitch.lua",
          query: [switchcmd: "getdevicelistinfos", sid: "$session_id"]
        } ->
          """
          <?xml version="1.0" encoding="UTF-8"?>
          <devicelist version="1">
          <device identifier="08761 0000434" id="17" functionbitmask="896" fwversion="03.33" manufacturer="AVM" productname="FRITZ!DECT 200">
            <present>1</present>
            <name>Steckdose</name>
            <switch>
               <state>1</state>
               <mode>auto</mode>
               <lock>0</lock>
               <devicelock>0</devicelock>
            </switch>
            <powermeter>
               <power>0</power>
               <energy>707</energy>
               <voltage>230252</voltage>
            </powermeter>
            <temperature>
               <celsius>285</celsius>
               <offset>0</offset>
            </temperature>
          </device>
          <device identifier="08761 1048079" id="16" functionbitmask="1280" fwversion="03.33" manufacturer="AVM" productname="FRITZ!DECT Repeater 100">
            <present>1</present>
            <name>FRITZ!DECT Rep 100 #1</name>
            <temperature>
               <celsius>288</celsius>
               <offset>0</offset>
            </temperature>
          </device>
          <group identifier="65:3A:18-900" id="900" functionbitmask="512" fwversion="1.0" manufacturer="AVM" productname="">
            <present>1</present>
            <name>Gruppe</name>
            <switch>
               <state>1</state>
               <mode>auto</mode>
               <lock />
               <devicelock />
            </switch>
            <groupinfo>
               <masterdeviceid>0</masterdeviceid>
               <members>17</members>
            </groupinfo>
          </group>
          </devicelist>
          """
          |> text(headers: [{"content-type", "text/xml"}])
      end)

      assert {:ok, [actor0, actor1]} = FritzApi.get_device_list_infos(client)

      assert actor0 == %Actor{
               ain: "087610000434",
               alert: nil,
               functions: ["Energie Messgerät", "Temperatursensor", "Schaltsteckdose"],
               fwversion: "03.33",
               id: 17,
               manufacturer: "AVM",
               name: "Steckdose",
               powermeter: %Powermeter{energy: 0.707, power: 0.0, voltage: 230.252},
               present: true,
               productname: "FRITZ!DECT 200",
               switch: %Switch{devicelock: false, lock: false, mode: :auto, state: true},
               temperature: %Temperature{celsius: 28.5, offset: 0.0}
             }

      assert actor1 == %Actor{
               ain: "087611048079",
               alert: nil,
               functions: ["Temperatursensor"],
               fwversion: "03.33",
               id: 16,
               manufacturer: "AVM",
               name: "FRITZ!DECT Rep 100 #1",
               powermeter: nil,
               present: true,
               productname: "FRITZ!DECT Repeater 100",
               switch: nil,
               temperature: %Temperature{celsius: 28.8, offset: 0.0}
             }
    end

    @tag logged_in: true
    test "handles empty fields", %{client: client} do
      mock(fn
        %Tesla.Env{
          method: :get,
          url: "http://fritz.box/webservices/homeautoswitch.lua",
          query: [switchcmd: "getdevicelistinfos", sid: "$session_id"]
        } ->
          """
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
          |> text(headers: [{"content-type", "text/xml"}])
      end)

      assert {:ok, [actor]} = FritzApi.get_device_list_infos(client)

      assert actor == %Actor{
               ain: "012340000123",
               fwversion: "03.87",
               functions: ["Energie Messgerät", "Temperatursensor", "Schaltsteckdose", "Mikrofon"],
               id: 51,
               manufacturer: "AVM",
               name: "Smart Plug",
               powermeter: %Powermeter{energy: nil, power: nil, voltage: nil},
               present: nil,
               productname: "FRITZ!DECT 200",
               switch: %Switch{devicelock: nil, lock: nil, mode: nil, state: nil},
               temperature: %Temperature{celsius: nil, offset: nil}
             }
    end
  end
end
