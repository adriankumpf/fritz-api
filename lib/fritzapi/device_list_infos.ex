defmodule Fritzapi.DeviceListInfos do
  @moduledoc """
  Implemented according to https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/AHA-HTTP-Interface.pdf
  """

  import SweetXml

  alias Fritzapi.Helper

  def parse_device_list(xml) do
    xml
    |> parse_xml
    |> remove_empty_functions
  end

  defp parse_xml(xml_string) do
    xpath(xml_string, ~x"/devicelist/device"l, device_list_schema())
  end

  defp remove_empty_functions(device_list) do
    Enum.map(device_list, &Helper.remove_nil_values/1)
  end

  defp device_list_schema do
    [
      fwversion: ~x"./@fwversion"s,
      id: ~x"./@id"i,
      ain: ~x"./@identifier"s |> transform_by(&String.replace(&1, " ", "")),
      manufacturer: ~x"./@manufacturer"s,
      productname: ~x"./@productname"s,
      present: ~x"./present/text()"i |> transform_by(&Helper.parse_boolean/1),
      name: ~x"./name/text()"s,
      switch: [
        ~x"./switch"o,
        state: ~x"./state/text()"i |> transform_by(&Helper.parse_boolean/1),
        mode: ~x"./mode/text()"s,
        lock: ~x"./lock/text()"i |> transform_by(&Helper.parse_boolean/1),
        devicelock: ~x"./devicelock/text()"i |> transform_by(&Helper.parse_boolean/1),
      ],
      powermeter: [
        ~x"./powermeter"o,
        power: ~x"./power/text()"s |> transform_by(&Helper.parse_float(&1, 3)),
        energy: ~x"./energy/text()"s |> transform_by(&Helper.parse_float(&1, 3))
      ],
      temperature: [
        ~x"./temperature"o,
        celsius: ~x"./celsius/text()"s |> transform_by(&Helper.parse_float(&1, 1)),
        offset: ~x"./offset/text()"s |> transform_by(&Helper.parse_float(&1, 1)),
      ],
      alert: [
        ~x"./alert"o,
        state: ~x"./state/text()"i |> transform_by(&Helper.parse_boolean/1),
      ],
      # TODO Heizkörperregler
      #
      # hkr: [
      #   ~x"./hkr"o,
      # ]
    ]
  end
end

