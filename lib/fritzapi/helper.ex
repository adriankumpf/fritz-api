defmodule Fritzapi.Helper do

  def md5(data) do
    data
    |> :unicode.characters_to_binary(:utf8, {:utf16, :little})
    |> (&:crypto.hash(:md5, &1)).()
    |> Base.encode16(case: :lower)
  end

  def parse_boolean(0), do: false
  def parse_boolean(1), do: true
  def parse_boolean(_), do: :error

  def parse_float("", _) do
    NaN
  end
  def parse_float(str, dec_places) when byte_size(str) <= dec_places do
    NaN
  end
  def parse_float("0", _) do
    0
  end
  def parse_float(str, 0) do
    {float, ""} = Float.parse(str)
    float
  end
  def parse_float(string, dec_places) do
    {left, right} = String.split_at(string, dec_places * -1)
    {float, ""} = Float.parse(left <> "." <> right)
    float
  end
end
