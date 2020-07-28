defmodule FritzApi.SessionTest do
  use FritzApi.Case, async: true

  @challenge "1234567z"

  test "logs in the client with a user name and password ", %{client: client} do
    mock(fn
      %Tesla.Env{method: :get, url: "http://fritz.box/login_sid.lua", query: query} ->
        session_info =
          case query do
            [] ->
              session_info("0000000000000000", challenge: @challenge)

            [username: "admin", response: @challenge <> "-9e224a41eeefa284df7bb0f26c2913e2"] ->
              session_info("$session_id")
          end

        text(session_info, headers: [{"content-type", "text/xml"}])
    end)

    assert {:ok, %FritzApi.Client{session_id: "$session_id"}} =
             FritzApi.Client.login(client, "admin", "äbc")
  end

  test "returns the SID right away if the client is already logged in", %{client: client} do
    mock(fn
      %Tesla.Env{method: :get, url: "http://fritz.box/login_sid.lua", query: []} ->
        text(session_info("$session_id"), headers: [{"content-type", "text/xml"}])
    end)

    assert {:ok, %FritzApi.Client{session_id: "$session_id"}} =
             FritzApi.Client.login(%{client | session_id: "some_sid"}, "admin", "äbc")
  end

  test "reports the block time", %{client: client} do
    mock(fn
      %Tesla.Env{method: :get, url: "http://fritz.box/login_sid.lua", query: query} ->
        session_info =
          case query do
            [] ->
              session_info("0000000000000000", challenge: @challenge)

            [username: "admin", response: @challenge <> "-9e224a41eeefa284df7bb0f26c2913e2"] ->
              session_info("0000000000000000", block_time: 60)
          end

        text(session_info, headers: [{"content-type", "text/xml"}])
    end)

    assert {:error, %FritzApi.Error{reason: {:login_failed, [block_time: 60]}}} =
             FritzApi.Client.login(client, "admin", "äbc")
  end

  defp session_info(sid, opts \\ []) do
    """
    <SessionInfo>
      <SID>#{sid}</SID>
      <Challenge>#{opts[:challenge]}</Challenge>
      <BlockTime>#{opts[:block_time] || 0}</BlockTime>
      <Rights>
        <Name>NAS</Name>
        <Access>2</Access>
        <Name>App</Name>
        <Access>2</Access>
        <Name>HomeAuto</Name>
        <Access>2</Access>
        <Name>BoxAdmin</Name>
        <Access>2</Access>
        <Name>Phone</Name>
        <Access>2</Access>
      </Rights>
    </SessionInfo>
    """
  end
end
