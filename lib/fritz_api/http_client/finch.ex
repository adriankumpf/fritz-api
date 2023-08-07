defmodule FritzApi.HTTPClient.Finch do
  @moduledoc """
  The built-in HTTP client, based on [finch](https://github.com/sneako/finch).

  It client implements the `FritzApi.HTTPClient` behaviour.

  See `FritzApi` for the available configuration options and `FritzApi.HTTPClient` if you wish to
  use another HTTP client.
  """

  @behaviour FritzApi.HTTPClient

  @finch_pool_name FritzApi.Finch

  @impl true
  def child_spec(pool_opts) do
    Finch.child_spec(name: @finch_pool_name, pools: %{default: pool_opts})
  end

  @impl true
  def get(url, opts) do
    req = Finch.build(:get, url)

    case Finch.request(req, @finch_pool_name, opts) do
      {:ok, %{status: status, headers: headers, body: body}} ->
        {:ok, status, headers, body}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
