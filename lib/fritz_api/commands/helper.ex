defmodule FritzApi.Commands.Helper do
  @moduledoc false

  @spec parse_boolean(integer()) :: :error | false | true
  def parse_boolean(0), do: false
  def parse_boolean(1), do: true
  def parse_boolean(_), do: :error

  @spec parse_float(String.t, integer()) :: float()
  def parse_float(string, dec_places) do
    string
    |> Integer.parse
    |> elem(0)
    |> Kernel./(:math.pow(10, dec_places))
  end

  @spec remove_nil_values(map()) :: map()
  def remove_nil_values(map) when is_map(map) do
    map
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})
  end
end
