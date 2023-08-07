defmodule FritzApi.HTTPClient.FinchTest do
  use ExUnit.Case, async: true

  alias FritzApi.HTTPClient

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "child_spec/1 passed configures the pool" do
    assert HTTPClient.Finch.child_spec(pool_max_idle_time: 5_000) ==
             Finch.child_spec(
               name: FritzApi.Finch,
               pools: %{default: [pool_max_idle_time: 5_000]}
             )
  end

  test "get/1 wraps Finch.request/3", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("x-foo", "bar")
      |> Plug.Conn.resp(200, "ok")
    end)

    assert {:ok, 200, resp_headers, "ok"} =
             HTTPClient.Finch.get("http://localhost:#{bypass.port}/", [])

    assert {_, "bar"} = List.keyfind(resp_headers, "x-foo", 0)
  end

  test "get/1 passes the requst options", %{bypass: bypass} do
    Bypass.stub(bypass, "GET", "/", fn conn ->
      Process.sleep(5)
      Plug.Conn.resp(conn, 200, "ok")
    end)

    assert {:error, %Mint.TransportError{reason: :timeout}} =
             HTTPClient.Finch.get("http://localhost:#{bypass.port}/", receive_timeout: 0)
  end

  test "get/1 handles errors", %{bypass: bypass} do
    Bypass.down(bypass)

    assert {:error, %Mint.TransportError{reason: :econnrefused}}
    HTTPClient.Finch.get("http://localhost:#{bypass.port}/", [])
  end
end
