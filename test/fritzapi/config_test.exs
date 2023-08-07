defmodule FritzApi.ConfigTest do
  use FritzApi.Case, async: false

  alias FritzApi.Config

  test "client/0 returns the built-in client" do
    assert Config.client() == FritzApi.HTTPClient.Finch
  end

  @config [client: MyClient]
  test "client/0 returns the configured client module" do
    assert Config.client() == MyClient
  end

  test "client_pool_opts/0 returns an empty list by default" do
    assert Config.client_pool_opts() == []
  end

  @config [client_pool_opts: [size: 10]]
  test "client_pool_opts/0 returns the configured pool options" do
    assert Config.client_pool_opts() == [size: 10]
  end

  test "client_request_opts/0 returns an empty list by default" do
    assert Config.client_request_opts() == []
  end

  @config [client_request_opts: [receive_timeout: 10_000]]
  test "client_request_opts/0 returns the configured pool options" do
    assert Config.client_request_opts() == [receive_timeout: 10_000]
  end
end
