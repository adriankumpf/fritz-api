defmodule FritzApi.Helper do
  @moduledoc false

  def md5(data) do
    data
    |> :unicode.characters_to_binary(:utf8, {:utf16, :little})
    |> (&:crypto.hash(:md5, &1)).()
    |> Base.encode16(case: :lower)
  end

  def parse_boolean(0), do: false
  def parse_boolean(1), do: true
  def parse_boolean(_), do: :error

  def parse_float(string, dec_places) do
    string
    |> Integer.parse
    |> elem(0)
    |> Kernel./(:math.pow(10, dec_places))
  end

  def remove_nil_values(map) when is_map(map) do
    map
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})
  end
end
