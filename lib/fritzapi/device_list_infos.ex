defmodule Fritzapi.DeviceListInfos do
  @moduledoc """
  According to https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/AHA-HTTP-Interface.pdf

  TODO: Heizkörperregler
  """

  import SweetXml

  alias Fritzapi.{FritzBox, Options}

  @path "/webservices/homeautoswitch.lua"

  def fetch(sid, %Options{base: base}) do
    qs = URI.encode_query(%{sid: sid, switchcmd: "getdevicelistinfos"})

    {:ok, devicelist_xml} = FritzBox.get(@path <> "?" <> qs , base)

    devicelist_xml
    |> xpath( ~x"/devicelist/device"l, device_list_struct() )
    |> Enum.map(&remove_optionals/1)
  end

  defp remove_optionals(device) do
    device
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})
  end

  defp device_list_struct do
    [
      functionbitmask: ~x"./@functionbitmask"i,
      fwversion: ~x"./@fwversion"s,
      id: ~x"./@id"i,
      identifier: ~x"./@identifier"s,
      manufacturer: ~x"./@manufacturer"s,
      productname: ~x"./@productname"s,
      present: ~x"./present/text()"i |> transform_by(& &1 === 1),
      name: ~x"./name/text()"s,
      switch: [
        ~x"./switch"o,
        state: ~x"./state/text()"i |> transform_by(& &1 === 1),
        mode: ~x"./mode/text()"s,
        lock: ~x"./lock/text()"i |> transform_by(& &1 === 1),
        devicelock: ~x"./devicelock/text()"i |> transform_by(& &1 === 1),
      ],
      powermeter: [
        ~x"./powermeter"o,
        power: ~x"./power/text()"s |> transform_by(& parse_float(&1, 3)),
        energy: ~x"./energy/text()"s |> transform_by(& parse_float(&1, 1))
      ],
      temperature: [
        ~x"./temperature"o,
        celsius: ~x"./celsius/text()"s |> transform_by(& parse_float(&1, 1)),
        offset: ~x"./offset/text()"s |> transform_by(& parse_float(&1, 1)),
      ],
      alert: [
        ~x"./alert"o,
        state: ~x"./state/text()"i |> transform_by(& &1 === 1),
      ]
    ]
  end

  defp parse_float("0", _) do
    0
  end
  defp parse_float(string, dec_places) do
    {left, right} = String.split_at(string, dec_places * -1)
    {float, ""} = Float.parse(left <> "." <> right)
    float
  end
end

