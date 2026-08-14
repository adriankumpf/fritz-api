defmodule FritzApi.CommandsTest do
  use FritzApi.Case, async: true

  alias FritzApi.{Actor, Alert, Error, Powermeter, Switch, Temperature}

  @ain "087610000434"

  defp mock_devicelist(xml) do
    mock(fn @command_url, [switchcmd: "getdevicelistinfos", sid: @session_id], _opts ->
      {:ok, 200, [{"content-type", "text/xml"}], xml}
    end)
  end

  describe "get_device_list_infos/1" do
    @logged_in true
    test "returns one actor if the devicelist contains one device", %{client: client} do
      mock_devicelist("""
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
      """)

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

    @logged_in true
    test "returns actors", %{client: client} do
      mock_devicelist("""
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
      """)

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

    @logged_in true
    test "handles empty fields", %{client: client} do
      mock_devicelist("""
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
      """)

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

    @logged_in true
    test "decodes an alert sensor", %{client: client} do
      mock_devicelist("""
      <devicelist version="1">
        <device identifier="01234 0000123" id="51" functionbitmask="16" fwversion="03.87"
                manufacturer="AVM" productname="FRITZ!DECT 440">
          <present>1</present>
          <name>Fenster</name>
          <alert>
            <state>1</state>
            <lastalertchgtimestamp>1700000000</lastalertchgtimestamp>
          </alert>
        </device>
      </devicelist>
      """)

      assert {:ok, [%Actor{alert: alert, functions: ["Alarm-Sensor"]}]} =
               FritzApi.get_device_list_infos(client)

      assert alert == %Alert{state: true, last_alert_change: ~U[2023-11-14 22:13:20Z]}
    end

    @logged_in true
    test "returns an empty list if no devices are paired", %{client: client} do
      mock_devicelist(~s(<devicelist version="1"/>))

      assert {:ok, []} = FritzApi.get_device_list_infos(client)
    end

    @logged_in true
    test "decodes values it does not recognise as nil", %{client: client} do
      mock_devicelist("""
      <devicelist version="1">
        <device identifier="01234 0000123" id="notanint" functionbitmask="garbage">
          <present>2</present>
          <switch><state>7</state><mode>weird</mode></switch>
          <newfangled>surprise</newfangled>
        </device>
      </devicelist>
      """)

      assert {:ok, [actor]} = FritzApi.get_device_list_infos(client)

      assert actor.ain == "012340000123"
      assert actor.id == nil
      assert actor.functions == []
      assert actor.present == nil
      assert actor.switch == %Switch{devicelock: nil, lock: nil, mode: nil, state: nil}
    end

    @logged_in true
    test "returns an error if the response is not a devicelist", %{client: client} do
      mock_devicelist("<html><body>Internal Error</body></html>")

      assert {:error, %Error{reason: {:unexpected_response, _}}} =
               FritzApi.get_device_list_infos(client)
    end
  end

  describe "get_switch_list/1" do
    defp mock_switch_list(body) do
      mock(fn @command_url, [switchcmd: "getswitchlist", sid: @session_id], _opts ->
        {:ok, 200, [{"content-type", "text/plain; charset=utf-8"}], body}
      end)
    end

    @logged_in true
    test "returns the AINs of all known switches", %{client: client} do
      mock_switch_list("000,111,222,333\n")

      assert {:ok, ["000", "111", "222", "333"]} = FritzApi.get_switch_list(client)
    end

    @logged_in true
    test "ignores trailing whitespace", %{client: client} do
      mock_switch_list("000,111\r\n")

      assert {:ok, ["000", "111"]} = FritzApi.get_switch_list(client)
    end

    @logged_in true
    test "returns an empty list if there are no switches", %{client: client} do
      mock_switch_list("\n")

      assert {:ok, []} = FritzApi.get_switch_list(client)
    end
  end

  describe "set_switch_*/2" do
    @logged_in true
    test "turns on a switch", %{client: client} do
      mock_command("setswitchon", %{"087610000434" => "1\n"})

      assert :ok = FritzApi.set_switch_on(client, "087610000434")
    end

    @logged_in true
    test "turns off a switch", %{client: client} do
      mock_command("setswitchoff", %{"087610000434" => "0\n"})

      assert :ok = FritzApi.set_switch_off(client, "087610000434")
    end

    @logged_in true
    test "toggles a switch", %{client: client} do
      mock_command("setswitchtoggle", %{"087610000434" => "0\n", "087610000435" => "1\n"})

      assert {:ok, :off} = FritzApi.set_switch_toggle(client, "087610000434")
      assert {:ok, :on} = FritzApi.set_switch_toggle(client, "087610000435")
    end
  end

  # Each case is a raw response body and the value the command should decode it
  # to. The AIN is irrelevant to all of them, so they all reuse @ain.
  for {fun, cmd, cases} <- [
        {:get_switch_state, "getswitchstate",
         [{"0\n", :off}, {"1\n", :on}, {"inval\n", :unknown}]},
        {:get_switch_present, "getswitchpresent", [{"0", false}, {"1", true}]},
        {:get_switch_power, "getswitchpower",
         [{"0", +0.0}, {"3500000", 3500.0}, {"inval", :unknown}]},
        {:get_switch_energy, "getswitchenergy",
         [{"0", +0.0}, {"3500000", 3500.0}, {"inval", :unknown}]},
        {:get_switch_name, "getswitchname", [{"Smart Plug", "Smart Plug"}]},
        {:get_temperature, "gettemperature",
         [{"0", +0.0}, {"200", 20.0}, {"-025", -2.5}, {"inval", :unknown}]}
      ] do
    @logged_in true
    test "#{fun}/2", %{client: client} do
      for {body, expected} <- unquote(Macro.escape(cases)) do
        mock_command(unquote(cmd), %{@ain => body})

        assert {:ok, ^expected} = FritzApi.unquote(fun)(client, @ain)
      end
    end
  end

  @logged_in true
  test "reports an unexpected response instead of crashing", %{client: client} do
    mock_command("getswitchstate", %{@ain => "yes"})

    assert {:error, %Error{reason: {:unexpected_response, "yes"}}} =
             FritzApi.get_switch_state(client, @ain)
  end

  @logged_in true
  test "rejects a blank AIN", %{client: client} do
    assert_raise FunctionClauseError, fn -> FritzApi.get_switch_state(client, "") end
  end

  describe "hkr" do
    @hkr_responses %{
      "087610000434" => "16",
      "087610000435" => "56",
      "087610000436" => "253",
      "087610000437" => "254"
    }

    for {fun, cmd} <- [
          get_hkr_target_temperature: "gethkrtsoll",
          get_hkr_comfort_temperature: "gethkrkomfort",
          get_hkr_economy_temperature: "gethkrabsenk"
        ] do
      @logged_in true
      test "#{fun}/2", %{client: client} do
        mock_command(unquote(cmd), @hkr_responses)

        assert {:ok, 8.0} = FritzApi.unquote(fun)(client, "087610000434")
        assert {:ok, 28.0} = FritzApi.unquote(fun)(client, "087610000435")
        assert {:ok, :off} = FritzApi.unquote(fun)(client, "087610000436")
        assert {:ok, :on} = FritzApi.unquote(fun)(client, "087610000437")
      end
    end

    @logged_in true
    test "reports an out-of-range target temperature", %{client: client} do
      mock_command("gethkrtsoll", %{"087610000434" => "0"})

      assert {:error, %Error{reason: {:unexpected_response, "0"}}} =
               FritzApi.get_hkr_target_temperature(client, "087610000434")
    end

    @logged_in true
    test "set_hkr_target_temperature/3 rounds to the nearest half degree", %{client: client} do
      mock_command("sethkrtsoll", &echo_param/1)

      for {temp, param} <- [{8.0, "16"}, {28.0, "56"}, {8.6, "17"}, {27.9, "56"}] do
        assert :ok = FritzApi.set_hkr_target_temperature(client, @ain, temp)
        assert_received {:param, ^param}
      end
    end

    test "set_hkr_target_temperature/3 rejects temperatures outside 8..28", %{client: client} do
      assert_raise FunctionClauseError, fn ->
        FritzApi.set_hkr_target_temperature(client, "087610000434", 7.9)
      end

      assert_raise FunctionClauseError, fn ->
        FritzApi.set_hkr_target_temperature(client, "087610000434", 28.1)
      end
    end

    @logged_in true
    test "enable_hkr_target_temperature/2", %{client: client} do
      mock_command("sethkrtsoll", &echo_param/1)

      assert :ok = FritzApi.enable_hkr_target_temperature(client, @ain)
      assert_received {:param, "254"}
    end

    @logged_in true
    test "disable_hkr_target_temperature/2", %{client: client} do
      mock_command("sethkrtsoll", &echo_param/1)

      assert :ok = FritzApi.disable_hkr_target_temperature(client, @ain)
      assert_received {:param, "253"}
    end

    # The box echoes the parameter it applied; forward it so the assertion can
    # live in the test rather than inside the mock.
    defp echo_param(params) do
      send(self(), {:param, params[:param]})
      params[:param]
    end
  end
end
