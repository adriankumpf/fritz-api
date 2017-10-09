defmodule FritzApi.Commands.DeviceListInfos do
  @moduledoc """
  """
  import SweetXml

  alias FritzApi.Commands.Helper

  @type t :: [%{
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
  }]

  @doc false
  @spec parse_device_list(String.t) :: t
  def parse_device_list(xml) do
    xml
    |> parse_xml
    |> remove_empty_functions
  end

  @spec parse_xml(String.t) :: t
  defp parse_xml(xml_string) do
    xpath(xml_string, ~x"/devicelist/device"l, device_list_schema())
  end

  @spec remove_empty_functions(t) :: t
  defp remove_empty_functions(device_list) do
    Enum.map(device_list, &Helper.remove_nil_values/1)
  end

  @spec device_list_schema() :: [...]
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
      # hkr: [
      #   ~x"./hkr"o,
      # ]
    ]
  end
end
