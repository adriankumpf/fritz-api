defmodule FritzApi.ErrorTest do
  use FritzApi.Case, async: true

  test "formats the error message" do
    error = %FritzApi.Error{reason: :unknown, response: {503, [], ""}}
    assert "unknown" == Exception.message(error)
  end
end
