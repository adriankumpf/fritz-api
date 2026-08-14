defmodule FritzApi.ClientTest do
  use FritzApi.Case, async: true

  alias FritzApi.{Client, Error}

  describe "login/3" do
    @challenge "1234567z"
    @response @challenge <> "-9e224a41eeefa284df7bb0f26c2913e2"

    defp session_info(sid, opts \\ []) do
      """
      <SessionInfo>
        <SID>#{sid}</SID>
        <Challenge>#{opts[:challenge]}</Challenge>
        <BlockTime>#{opts[:block_time] || 0}</BlockTime>
        <Rights>
          <Name>HomeAuto</Name>
          <Access>2</Access>
        </Rights>
      </SessionInfo>
      """
    end

    defp mock_login(answer) do
      mock(fn @login_url, query, _opts ->
        {:ok, 200, [{"content-type", "text/xml"}], answer.(query)}
      end)
    end

    test "logs in the client with a user name and password", %{client: client} do
      mock_login(fn
        nil -> session_info("0000000000000000", challenge: @challenge)
        [username: "admin", response: @response] -> session_info(@session_id)
      end)

      assert {:ok, %Client{} = client} = Client.login(client, "admin", "äbc")
      assert Client.session_id(client) == @session_id
    end

    @logged_in true
    test "returns the SID right away if the client is already logged in", %{client: client} do
      mock_login(fn nil -> session_info(@session_id) end)

      assert {:ok, %Client{} = client} = Client.login(client, "admin", "äbc")
      assert Client.session_id(client) == @session_id
    end

    test "reports the block time", %{client: client} do
      mock_login(fn
        nil ->
          session_info("0000000000000000", challenge: @challenge)

        [username: "admin", response: @response] ->
          session_info("0000000000000000", block_time: 60)
      end)

      assert {:error, %Error{reason: {:login_failed, [block_time: 60]}}} =
               Client.login(client, "admin", "äbc")
    end

    test "reports the status if the box fails the login request", %{client: client} do
      mock(fn @login_url, _query, _opts -> {:ok, 500, [], ""} end)

      assert {:error, %Error{reason: :internal_error}} = Client.login(client, "admin", "äbc")
    end
  end

  describe "execute_command/3" do
    defp mock_status(status) do
      mock(fn _url, _query, _opts -> {:ok, status, [], ""} end)
    end

    @logged_in true
    test "returns error if the session is expired", %{client: client} do
      mock_status(403)

      assert {:error, %Error{reason: :session_expired}} = Client.execute_command(client, "foo")
    end

    test "returns error if the user is not logged in", %{client: client} do
      mock_status(403)

      assert {:error, %Error{reason: :user_not_authorized}} =
               Client.execute_command(client, "foo")
    end

    @logged_in true
    test "returns error if the actor does not exist", %{client: client} do
      mock_status(400)

      assert {:error, %Error{reason: :actor_not_found}} =
               Client.execute_command(client, "foo", ain: "123")
    end

    test "returns error if the request is invalid", %{client: client} do
      mock_status(400)

      assert {:error, %Error{reason: :bad_request}} = Client.execute_command(client, "foo")
    end

    test "returns error if there was a server error", %{client: client} do
      mock_status(500)

      assert {:error, %Error{reason: :internal_error}} = Client.execute_command(client, "foo")
    end

    test "returns error if something unexpected happened", %{client: client} do
      mock_status(503)

      assert {:error, %Error{reason: :unknown, response: {503, [], ""}}} ==
               Client.execute_command(client, "foo")
    end

    test "returns error if the request failed", %{client: client} do
      mock(fn _url, _query, _opts -> {:error, :timeout} end)

      assert {:error, %Error{reason: :timeout}} = Client.execute_command(client, "foo")
    end

    @logged_in true
    test "runs commands that FritzApi does not wrap", %{client: client} do
      mock(fn @command_url,
              [switchcmd: "setsimpleonoff", sid: @session_id, ain: "123", onoff: "2"],
              _opts ->
        {:ok, 200, [], "1\n"}
      end)

      assert {:ok, "1"} = Client.execute_command(client, "setsimpleonoff", ain: "123", onoff: 2)
    end
  end

  describe "new/1" do
    test "uses fritz.box as the default base URL", %{client: client} do
      mock(fn url, _query, _opts ->
        send(self(), {:url, url})
        {:ok, 200, [], ""}
      end)

      Client.execute_command(client, "foo")
      assert_received {:url, @command_url}
    end

    test "accepts a custom base URL" do
      client = Client.new(base_url: "http://192.168.1.1:8080", http_client: TestClient)

      mock(fn url, _query, _opts ->
        send(self(), {:url, url})
        {:ok, 200, [], ""}
      end)

      Client.execute_command(client, "foo")
      assert_received {:url, "http://192.168.1.1:8080/webservices/homeautoswitch.lua"}
    end
  end
end
