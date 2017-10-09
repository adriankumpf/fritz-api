defmodule FritzApi.Commands.HelperTest do
  use ExUnit.Case

  alias FritzApi.Commands.Helper

  test "parses booleans" do
    assert Helper.parse_boolean(0) === false
    assert Helper.parse_boolean(1) === true
    assert Helper.parse_boolean(99) === :error
  end

  test "parses floats with given number of decimal places" do
    assert Helper.parse_float("100999", 3) === 100.999
    assert Helper.parse_float("-0000999", 4) === -0.0999
    assert Helper.parse_float("0000999", 4) === 0.0999
    assert Helper.parse_float("100", 0) === 100.0
    assert Helper.parse_float("011", 3) === 0.011
  end
end

