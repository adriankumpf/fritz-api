defmodule FritzApi.SessionId.CryptoTest do
  use ExUnit.Case

  alias FritzApi.SessionId.Crypto

  test "generates MD5 hashes" do
    assert Crypto.md5("1234567z-äbc") == "9e224a41eeefa284df7bb0f26c2913e2"
  end
end

