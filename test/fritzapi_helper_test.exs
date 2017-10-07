defmodule FritzApiHelperTest do
  use ExUnit.Case

  test "generates MD5 hashes" do
    assert FritzApi.Helper.md5("1234567z-äbc") == "9e224a41eeefa284df7bb0f26c2913e2"
  end

  test "parses booleans" do
    assert FritzApi.Helper.parse_boolean(0) === false
    assert FritzApi.Helper.parse_boolean(1) === true
    assert FritzApi.Helper.parse_boolean(99) === :error
  end

  test "parses floats with given number of decimal places" do
    assert FritzApi.Helper.parse_float("100999", 3) === 100.999
    assert FritzApi.Helper.parse_float("-0000999", 4) === -0.0999
    assert FritzApi.Helper.parse_float("0000999", 4) === 0.0999
    assert FritzApi.Helper.parse_float("100", 0) === 100.0
    assert FritzApi.Helper.parse_float("011", 3) === 0.011
  end
end

