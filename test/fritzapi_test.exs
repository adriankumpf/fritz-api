defmodule FritzapiTest do
  use ExUnit.Case
  doctest Fritzapi

  test "greets the world" do
    assert Fritzapi.hello() == :world
  end
end
