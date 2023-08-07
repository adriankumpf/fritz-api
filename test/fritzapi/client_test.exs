defmodule FritzApi.ClientTest do
  use FritzApi.Case, async: true

  describe "login/3" do
    @challenge "1234567z"

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

    test "logs in the client with a user name and password ", %{client: client} do
      mock(fn "http://fritz.box/login_sid.lua", query, _opts ->
        session_info =
          case query do
            nil ->
              session_info("0000000000000000", challenge: @challenge)

            [username: "admin", response: @challenge <> "-9e224a41eeefa284df7bb0f26c2913e2"] ->
              session_info("$session_id")
          end

        {:ok, 200, [{"content-type", "text/xml"}], session_info}
      end)

      assert {:ok, %FritzApi.Client{session_id: "$session_id"}} =
               FritzApi.Client.login(client, "admin", "äbc")
    end

    @logged_in true
    test "returns the SID right away if the client is already logged in", %{client: client} do
      mock(fn "http://fritz.box/login_sid.lua", nil, _opts ->
        {:ok, 200, [{"content-type", "text/xml"}], session_info("$session_id")}
      end)

      assert {:ok, %FritzApi.Client{session_id: "$session_id"}} =
               FritzApi.Client.login(client, "admin", "äbc")
    end

    test "reports the block time", %{client: client} do
      mock(fn "http://fritz.box/login_sid.lua", query, _opts ->
        session_info =
          case query do
            nil ->
              session_info("0000000000000000", challenge: @challenge)

            [username: "admin", response: @challenge <> "-9e224a41eeefa284df7bb0f26c2913e2"] ->
              session_info("0000000000000000", block_time: 60)
          end

        {:ok, 200, [{"content-type", "text/xml"}], session_info}
      end)

      assert {:error, %FritzApi.Error{reason: {:login_failed, [block_time: 60]}}} =
               FritzApi.Client.login(client, "admin", "äbc")
    end
  end

  describe "get/3" do
    defp mock_respond_with_status(status) do
      mock(fn _url, _query, _opts ->
        {:ok, status, [], ""}
      end)
    end

    @logged_in true
    test "returns error if the session is expired", %{client: client} do
      mock_respond_with_status(403)

      assert {:error, %FritzApi.Error{reason: :session_expired}} =
               FritzApi.Client.execute_command(client, "foo", sid: client.session_id)
    end

    @logged_in false
    test "returns error if the user is not logged in", %{client: client} do
      mock_respond_with_status(403)

      assert {:error, %FritzApi.Error{reason: :user_not_authorized}} =
               FritzApi.Client.execute_command(client, "foo")
    end

    @logged_in true
    test "returns error if the actor does not exist", %{client: client} do
      mock_respond_with_status(400)

      assert {:error, %FritzApi.Error{reason: :actor_not_found}} =
               FritzApi.Client.execute_command(client, "foo", ain: "123")
    end

    test "returns error if the request is invalid", %{client: client} do
      mock_respond_with_status(400)

      assert {:error, %FritzApi.Error{reason: :bad_request}} =
               FritzApi.Client.execute_command(client, "foo", sid: client.session_id)
    end

    test "returns error if there was a server error", %{client: client} do
      mock_respond_with_status(500)

      assert {:error, %FritzApi.Error{reason: :internal_error}} =
               FritzApi.Client.execute_command(client, "foo", sid: client.session_id)
    end

    test "returns error if something unexpected happened", %{client: client} do
      mock_respond_with_status(503)

      assert {:error, %FritzApi.Error{reason: :unknown, response: {503, [], ""}}} ==
               FritzApi.Client.execute_command(client, "foo", sid: client.session_id)
    end

    test "returns error if the request failed", %{client: client} do
      mock(fn _url, _query, _opts ->
        {:error, :timeout}
      end)

      assert {:error, %FritzApi.Error{reason: :timeout}} =
               FritzApi.Client.execute_command(client, "foo", sid: client.session_id)
    end
  end
end
