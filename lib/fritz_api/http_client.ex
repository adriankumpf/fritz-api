defmodule FritzApi.HTTPClient do
  @moduledoc """
  Specifies the API for using a custom HTTP Client.

  The default HTTP client is `FritzApi.HTTPClient.Finch`.

  To configure a different HTTP client, implement the `FritzApi.HTTPClient` behaviour
  and change the `:client` configuration:

      config :fritz_api, :client, HackneyClient

  """

  @moduledoc since: "3.0.0"

  @typedoc "HTTP request method."
  @type method :: atom()

  @typedoc "HTTP request URL."
  @type url :: String.t()

  @typedoc "HTTP response status."
  @type status :: 100..599

  @typedoc "HTTP request or response headers."
  @type headers :: [{String.t(), String.t()}]

  @typedoc "HTTP request query params."
  @type params :: keyword()

  @typedoc "HTTP request or response body."
  @type body :: binary()

  @typedoc "Options to configure the pool (set via `:client_pool_opts`)."
  @type pool_opts :: Keyword.t()

  @typedoc "HTTP request options (set via `:client_request_opts`)."
  @type req_opts :: Keyword.t()

  @doc """
  Should return a **child specification** to start the HTTP client or `nil`.

  For example, this can start a pool of HTTP connections dedicated to FritzApi.
  """
  @callback child_spec(pool_opts) :: Supervisor.child_spec() | nil

  @doc """
  Should make an HTTP request to `url`.
  """
  @callback get(url, req_opts) :: {:ok, status, headers, body} | {:error, term}
end
