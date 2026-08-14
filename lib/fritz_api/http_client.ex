defmodule FritzApi.HTTPClient do
  @moduledoc """
  Specifies the API for using a custom HTTP Client.

  The default HTTP client is `FritzApi.HTTPClient.Finch`.

  To configure a different HTTP client, implement the `FritzApi.HTTPClient` behaviour
  and change the `:client` configuration:

      config :fritz_api, :client, MyHTTPClient

  ## Example

  A client implementation based on `:hackney` could look like this:

      defmodule MyHTTPClient do
        @behaviour FritzApi.HTTPClient

        @pool_name :my_http_client_pool

        @impl true
        def child_spec(pool_opts) do
          :hackney_pool.child_spec(@pool_name, pool_opts)
        end

        @impl true
        def get(url, req_opts) do
          opts = [:with_body, pool: @pool_name] ++ req_opts

          case :hackney.get(url, [], "", opts) do
            {:ok, _status, _headers, _body} = result -> result
            {:error, _reason} = error -> error
          end
        end
      end

  """
  @moduledoc since: "3.0.0"

  @typedoc "HTTP request URL."
  @type url :: String.t()

  @typedoc "HTTP response status."
  @type status :: 100..599

  @typedoc "HTTP response headers."
  @type headers :: [{String.t(), String.t()}]

  @typedoc "HTTP response body."
  @type body :: binary()

  @typedoc "Options to configure the pool (set via `:client_pool_opts`)."
  @type pool_opts :: Keyword.t()

  @typedoc "HTTP request options (set via `:client_request_opts`)."
  @type req_opts :: Keyword.t()

  @doc """
  Should return a **child specification** to start the HTTP client, a list of
  them, or `nil` if the client needs no supervised process.

  For example, this can start a pool of HTTP connections dedicated to FritzApi.
  """
  @callback child_spec(pool_opts) ::
              Supervisor.child_spec() | [Supervisor.child_spec()] | nil

  @doc """
  Should make an HTTP request to `t:url/0` with the given `t:req_opts/0`.
  """
  @callback get(url, req_opts) :: {:ok, status, headers, body} | {:error, term}
end
