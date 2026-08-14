defmodule FritzApi.ErrorTest do
  use ExUnit.Case, async: true

  alias FritzApi.Error

  defp message(reason), do: Exception.message(%Error{reason: reason})

  test "formats atom reasons" do
    assert message(:unknown) == "unknown"
    assert message(:session_expired) == "session_expired"
  end

  test "formats a failed login" do
    assert message({:login_failed, block_time: 0}) == "login failed"
    assert message({:login_failed, block_time: 60}) == "login failed, blocked for 60 seconds"
  end

  test "formats an unexpected response" do
    assert message({:unexpected_response, "yes"}) == ~s(unexpected response: "yes")
  end

  test "formats an exception raised by the HTTP client" do
    assert message(%RuntimeError{message: "boom"}) == "boom"
  end

  test "falls back to inspecting the reason" do
    assert message({:weird, 1}) == "{:weird, 1}"
  end
end
