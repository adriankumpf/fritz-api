defmodule FritzApi.Commands.Helper do
  @moduledoc false

  @spec parse_boolean(integer | String.t) :: boolean | nil
  def parse_boolean(0), do: false
  def parse_boolean(1), do: true
  def parse_boolean("0"), do: false
  def parse_boolean("1"), do: true
  def parse_boolean(_), do: nil

  @spec parse_list(String.t) :: [String.t]
  def parse_list(""), do: []
  def parse_list(str) when is_binary(str), do: String.split(str, ",")

  @spec parse_float(String.t, integer) :: float | nil
  def parse_float(string, dec_places) do
    case Integer.parse(string) do
      {val, ""} -> val / :math.pow(10, dec_places)
      _ -> nil
    end
  end
end
