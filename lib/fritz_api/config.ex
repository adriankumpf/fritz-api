defmodule FritzApi.Config do
  @moduledoc false

  def client, do: Application.get_env(:fritz_api, :client, FritzApi.HTTPClient.Finch)
  def client_pool_opts, do: Application.get_env(:fritz_api, :client_pool_opts, [])
  def client_request_opts, do: Application.get_env(:fritz_api, :client_request_opts, [])
end
