defmodule FritzApi.Commands.DeviceListInfos do
  @moduledoc false

  import SweetXml

  alias FritzApi.Commands.Helper
  alias FritzApi.Actor

  @spec parse_device_list(String.t()) :: [Actor.t()]
  def parse_device_list(xml) do
    xml
    |> parse_xml
    |> create_actors
  end

  @spec parse_xml(String.t()) :: [map]
  defp parse_xml(xml_string) do
    xpath(xml_string, ~x"/devicelist/device"l, device_list_schema())
  end

  @spec device_list_schema() :: [...]
  defp device_list_schema do
    [
      fwversion: ~x"./@fwversion"s,
      id: ~x"./@id"i,
      ain: ~x"./@identifier"s |> transform_by(&parse_ain/1),
      manufacturer: ~x"./@manufacturer"s,
      productname: ~x"./@productname"s,
      name: ~x"./name/text()"s,
      present: ~x"./present/text()"s |> transform_by(&Helper.parse_boolean/1),
      switch: [
        ~x"./switch"o,
        state: ~x"./state/text()"s |> transform_by(&Helper.parse_boolean/1),
        mode: ~x"./mode/text()"s |> transform_by(&parse_mode/1),
        lock: ~x"./lock/text()"s |> transform_by(&Helper.parse_boolean/1),
        devicelock:
          ~x"./devicelock/text()"s
          |> transform_by(&Helper.parse_boolean/1)
      ],
      powermeter: [
        ~x"./powermeter"o,
        power: ~x"./power/text()"s |> transform_by(&Helper.parse_float(&1, 3)),
        energy:
          ~x"./energy/text()"s
          |> transform_by(&Helper.parse_float(&1, 3))
      ],
      temperature: [
        ~x"./temperature"o,
        celsius:
          ~x"./celsius/text()"s
          |> transform_by(&Helper.parse_float(&1, 1)),
        offset:
          ~x"./offset/text()"s
          |> transform_by(&Helper.parse_float(&1, 1))
      ],
      alert: [
        ~x"./alert"o,
        state: ~x"./state/text()"s |> transform_by(&Helper.parse_boolean/1)
      ]
      # hkr: [
      #   ~x"./hkr"o,
      # ]
    ]
  end

  @spec parse_ain(String.t()) :: String.t()
  defp parse_ain(str), do: String.replace(str, " ", "")

  @spec parse_mode(String.t()) :: :manual | :auto | nil
  defp parse_mode("manuell"), do: :manual
  defp parse_mode("auto"), do: :auto
  defp parse_mode(_), do: nil

  @spec create_actors([map]) :: [Actor.t()]
  defp create_actors(devicelist) do
    Enum.map(devicelist, fn device -> struct(Actor, device) end)
  end
end
