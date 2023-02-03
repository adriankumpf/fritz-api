defmodule FritzApi.CommandsTest do
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

  describe "get_switch_list/1" do
    @tag logged_in: true
    test "returns the AINs of all known switches", %{client: client} do
      mock(fn
        %Tesla.Env{
          method: :get,
          url: "http://fritz.box/webservices/homeautoswitch.lua",
          query: [switchcmd: "getswitchlist", sid: "$session_id"]
        } ->
          text("000,111,222,333\n", headers: [{"content-type", "text/plain; charset=utf-8"}])
      end)

      assert {:ok, ["000", "111", "222", "333"]} = FritzApi.get_switch_list(client)
    end
  end

  describe "set_switch_*/2" do
    @tag logged_in: true
    test "turns on a switch", %{client: client} do
      mock(fn
        %Tesla.Env{
          method: :get,
          url: "http://fritz.box/webservices/homeautoswitch.lua",
          query: [switchcmd: "setswitchon", sid: "$session_id", ain: "087610000434"]
        } ->
          text("1\n")
      end)

      assert :ok = FritzApi.set_switch_on(client, "087610000434")
    end

    @tag logged_in: true
    test "turns off a switch", %{client: client} do
      mock(fn
        %Tesla.Env{
          method: :get,
          url: "http://fritz.box/webservices/homeautoswitch.lua",
          query: [switchcmd: "setswitchoff", sid: "$session_id", ain: "087610000434"]
        } ->
          text("0\n")
      end)

      assert :ok = FritzApi.set_switch_off(client, "087610000434")
    end

    @tag logged_in: true
    test "toggles a switch", %{client: client} do
      mock(fn
        %Tesla.Env{
          method: :get,
          url: "http://fritz.box/webservices/homeautoswitch.lua",
          query: [switchcmd: "setswitchtoggle", sid: "$session_id", ain: ain]
        } ->
          case ain do
            "087610000434" -> text("0\n")
            "087610000435" -> text("1\n")
          end
      end)

      assert {:ok, :off} = FritzApi.set_switch_toggle(client, "087610000434")
      assert {:ok, :on} = FritzApi.set_switch_toggle(client, "087610000435")
    end
  end

  @tag logged_in: true
  test "get_switch_state/2", %{client: client} do
    mock(fn
      %Tesla.Env{
        method: :get,
        url: "http://fritz.box/webservices/homeautoswitch.lua",
        query: [switchcmd: "getswitchstate", sid: "$session_id", ain: ain]
      } ->
        case ain do
          "087610000434" -> text("0\n")
          "087610000435" -> text("1\n")
          "087610000436" -> text("inval\n")
        end
    end)

    assert {:ok, :off} = FritzApi.get_switch_state(client, "087610000434")
    assert {:ok, :on} = FritzApi.get_switch_state(client, "087610000435")
    assert {:ok, :unknown} = FritzApi.get_switch_state(client, "087610000436")
  end

  @tag logged_in: true
  test "get_switch_present/2", %{client: client} do
    mock(fn
      %Tesla.Env{
        method: :get,
        url: "http://fritz.box/webservices/homeautoswitch.lua",
        query: [switchcmd: "getswitchpresent", sid: "$session_id", ain: ain]
      } ->
        case ain do
          "087610000434" -> text("0")
          "087610000435" -> text("1")
        end
    end)

    assert {:ok, false} = FritzApi.get_switch_present(client, "087610000434")
    assert {:ok, true} = FritzApi.get_switch_present(client, "087610000435")
  end

  @tag logged_in: true
  test "get_switch_power/2", %{client: client} do
    mock(fn
      %Tesla.Env{
        method: :get,
        url: "http://fritz.box/webservices/homeautoswitch.lua",
        query: [switchcmd: "getswitchpower", sid: "$session_id", ain: ain]
      } ->
        case ain do
          "087610000434" -> text("0")
          "087610000435" -> text("3500000")
          "087610000436" -> text("inval")
        end
    end)

    assert {:ok, 0.0} = FritzApi.get_switch_power(client, "087610000434")
    assert {:ok, 3500.0} = FritzApi.get_switch_power(client, "087610000435")
    assert {:ok, :unknown} = FritzApi.get_switch_power(client, "087610000436")
  end

  @tag logged_in: true
  test "get_switch_energy/2", %{client: client} do
    mock(fn
      %Tesla.Env{
        method: :get,
        url: "http://fritz.box/webservices/homeautoswitch.lua",
        query: [switchcmd: "getswitchenergy", sid: "$session_id", ain: ain]
      } ->
        case ain do
          "087610000434" -> text("0")
          "087610000435" -> text("3500000")
          "087610000436" -> text("inval")
        end
    end)

    assert {:ok, 0.0} = FritzApi.get_switch_energy(client, "087610000434")
    assert {:ok, 3500.0} = FritzApi.get_switch_energy(client, "087610000435")
    assert {:ok, :unknown} = FritzApi.get_switch_energy(client, "087610000436")
  end

  @tag logged_in: true
  test "get_switch_name/2", %{client: client} do
    mock(fn
      %Tesla.Env{
        method: :get,
        url: "http://fritz.box/webservices/homeautoswitch.lua",
        query: [switchcmd: "getswitchname", sid: "$session_id", ain: "087610000434"]
      } ->
        text("Smart Plug")
    end)

    assert {:ok, "Smart Plug"} = FritzApi.get_switch_name(client, "087610000434")
  end

  @tag logged_in: true
  test "get_temperature/2", %{client: client} do
    mock(fn
      %Tesla.Env{
        method: :get,
        url: "http://fritz.box/webservices/homeautoswitch.lua",
        query: [switchcmd: "gettemperature", sid: "$session_id", ain: ain]
      } ->
        case ain do
          "087610000434" -> text("0")
          "087610000435" -> text("200")
          "087610000436" -> text("-025")
          "087610000437" -> text("inval")
        end
    end)

    assert {:ok, 0.0} = FritzApi.get_temperature(client, "087610000434")
    assert {:ok, 20.0} = FritzApi.get_temperature(client, "087610000435")
    assert {:ok, -2.5} = FritzApi.get_temperature(client, "087610000436")
    assert {:ok, :unknown} = FritzApi.get_temperature(client, "087610000437")
  end

  describe "hkr" do
    @tag logged_in: true
    test "get_hkr_target_temperature/2", %{client: client} do
      mock(fn
        %Tesla.Env{
          method: :get,
          url: "http://fritz.box/webservices/homeautoswitch.lua",
          query: [switchcmd: "gethkrtsoll", sid: "$session_id", ain: ain]
        } ->
          case ain do
            "087610000434" -> text("16")
            "087610000435" -> text("56")
            "087610000436" -> text("253")
            "087610000437" -> text("254")
          end
      end)

      assert {:ok, 8.0} = FritzApi.get_hkr_target_temperature(client, "087610000434")
      assert {:ok, 28.0} = FritzApi.get_hkr_target_temperature(client, "087610000435")
      assert {:ok, :off} = FritzApi.get_hkr_target_temperature(client, "087610000436")
      assert {:ok, :on} = FritzApi.get_hkr_target_temperature(client, "087610000437")
    end

    @tag logged_in: true
    test "get_hkr_comfort_temperature/2", %{client: client} do
      mock(fn
        %Tesla.Env{
          method: :get,
          url: "http://fritz.box/webservices/homeautoswitch.lua",
          query: [switchcmd: "gethkrkomfort", sid: "$session_id", ain: ain]
        } ->
          case ain do
            "087610000434" -> text("16")
            "087610000435" -> text("56")
            "087610000436" -> text("253")
            "087610000437" -> text("254")
          end
      end)

      assert {:ok, 8.0} = FritzApi.get_hkr_comfort_temperature(client, "087610000434")
      assert {:ok, 28.0} = FritzApi.get_hkr_comfort_temperature(client, "087610000435")
      assert {:ok, :off} = FritzApi.get_hkr_comfort_temperature(client, "087610000436")
      assert {:ok, :on} = FritzApi.get_hkr_comfort_temperature(client, "087610000437")
    end

    @tag logged_in: true
    test "get_hkr_economy_temperature/2", %{client: client} do
      mock(fn
        %Tesla.Env{
          method: :get,
          url: "http://fritz.box/webservices/homeautoswitch.lua",
          query: [switchcmd: "gethkrabsenk", sid: "$session_id", ain: ain]
        } ->
          case ain do
            "087610000434" -> text("16")
            "087610000435" -> text("56")
            "087610000436" -> text("253")
            "087610000437" -> text("254")
          end
      end)

      assert {:ok, 8.0} = FritzApi.get_hkr_economy_temperature(client, "087610000434")
      assert {:ok, 28.0} = FritzApi.get_hkr_economy_temperature(client, "087610000435")
      assert {:ok, :off} = FritzApi.get_hkr_economy_temperature(client, "087610000436")
      assert {:ok, :on} = FritzApi.get_hkr_economy_temperature(client, "087610000437")
    end

    @tag logged_in: true
    test "set_hkr_target_temperature/3", %{client: client} do
      mock(fn
        %Tesla.Env{
          method: :get,
          url: "http://fritz.box/webservices/homeautoswitch.lua",
          query: [{:switchcmd, "sethkrtsoll"}, {:sid, "$session_id"} | query]
        } ->
          case {query[:ain], query[:param]} do
            {"087610000434", 16} -> text("")
            {"087610000435", 56} -> text("")
            {"087610000436", 17} -> text("")
            {"087610000437", 56} -> text("")
          end
      end)

      assert :ok = FritzApi.set_hkr_target_temperature(client, "087610000434", 8.0)
      assert :ok = FritzApi.set_hkr_target_temperature(client, "087610000435", 28.0)
      assert :ok = FritzApi.set_hkr_target_temperature(client, "087610000436", 8.6)
      assert :ok = FritzApi.set_hkr_target_temperature(client, "087610000437", 27.9)
    end

    @tag logged_in: true
    test "enable_hkr_target_temperature/2", %{client: client} do
      mock(fn
        %Tesla.Env{
          method: :get,
          url: "http://fritz.box/webservices/homeautoswitch.lua",
          query: [switchcmd: "sethkrtsoll", sid: "$session_id", ain: "087610000434", param: 254]
        } ->
          text("")
      end)

      assert :ok = FritzApi.enable_hkr_target_temperature(client, "087610000434")
    end

    @tag logged_in: true
    test "disable_hkr_target_temperature/2", %{client: client} do
      mock(fn
        %Tesla.Env{
          method: :get,
          url: "http://fritz.box/webservices/homeautoswitch.lua",
          query: [switchcmd: "sethkrtsoll", sid: "$session_id", ain: "087610000434", param: 253]
        } ->
          text("")
      end)

      assert :ok = FritzApi.disable_hkr_target_temperature(client, "087610000434")
    end
  end
end
