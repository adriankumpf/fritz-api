defmodule FritzApi.Client do
  @moduledoc """
  A FritzApi API Client
  """

  alias FritzApi.{Config, Error}

  @typedoc """
  A client, as returned by `new/1`.

  Treat the struct as private: build it with `new/1` and read the session ID
  with `session_id/1` rather than matching on the fields, which may change.
  """
  @type t :: %__MODULE__{
          base_url: String.t(),
          http_client: module(),
          request_opts: Keyword.t(),
          session_id: String.t() | nil
        }

  @enforce_keys [:base_url, :http_client, :request_opts]
  defstruct [:base_url, :http_client, :request_opts, :session_id]

  @base_url "http://fritz.box"
  @login_path "/login_sid.lua"
  @command_path "/webservices/homeautoswitch.lua"

  # The FritzBox returns this SID to signal "not authenticated".
  @no_session "0000000000000000"

  @doc """
  Creates a new FritzApi API client.

  ## Options

    * `:base_url` - the base URL for all endpoints (default: `#{@base_url}`)
    * `:http_client` - a module implementing the `FritzApi.HTTPClient` behaviour
      (default: the `:client` application environment value). Note that only the
      configured `:client` gets a connection pool started for it at boot.
    * `:request_opts` - options passed to `c:FritzApi.HTTPClient.get/2`
      (default: the `:client_request_opts` application environment value)
    * `:session_id` - an existing session ID, to reuse a session across restarts

  ## Examples

      iex> client = FritzApi.Client.new()
      %FritzApi.Client{}

  """
  @spec new(Keyword.t()) :: t
  def new(opts \\ []) do
    %__MODULE__{
      base_url: opts[:base_url] || @base_url,
      http_client: opts[:http_client] || Config.client(),
      request_opts: opts[:request_opts] || Config.client_request_opts(),
      session_id: opts[:session_id]
    }
  end

  @doc """
  Authenticate with the FritzApi API using the name and password of the user.

  A valid session ID is required in order to interact with the FritzBox API.

  Each application should only acquire a single session ID since the number of
  sessions to a FritzBox is limited.

  In principle, each session ID has a validity of 60 Minutes whereby the
  validity period gets extended with every access to the API. However, if any
  application tries to access the API with an invalid session ID, all other
  sessions get terminated.

  ## Examples

      iex> {:ok, client} = FritzApi.Client.new()
      ...>                 |> FritzApi.Client.login(username, password)
      {:ok, %FritzApi.Client{}}

  """
  @spec login(t, FritzApi.username(), FritzApi.password()) :: {:ok, t} | {:error, Error.t()}
  def login(%__MODULE__{} = client, username, password)
      when is_binary(username) and is_binary(password) do
    with {:ok, session_id} <- get_session_id(client, username, password) do
      {:ok, put_in(client.session_id, session_id)}
    end
  end

  @doc """
  Returns the session ID of a logged in client, or `nil`.
  """
  @spec session_id(t) :: String.t() | nil
  def session_id(%__MODULE__{session_id: session_id}), do: session_id

  @doc """
  Runs a home automation command and returns its decoded response body.

  `FritzApi` wraps the commonly used commands, but the FritzBox supports more
  than are wrapped here. Use this to reach the rest; see the [AVM Home
  Automation documentation](https://avm.de/service/schnittstellen/) for the
  available commands and their parameters.

  ## Examples

      iex> FritzApi.Client.execute_command(client, "setsimpleonoff", ain: ain, onoff: 2)
      {:ok, "1"}

  """
  @spec execute_command(t, String.t(), Keyword.t()) :: {:ok, term} | {:error, Error.t()}
  def execute_command(%__MODULE__{session_id: session_id} = client, cmd, params \\ []) do
    get(client, @command_path, [switchcmd: cmd, sid: session_id] ++ params)
  end

  defp get_session_id(client, username, password) do
    case login_request(client) do
      {:ok, %{"SID" => @no_session, "Challenge" => challenge}} when is_binary(challenge) ->
        answer_challenge(client, username, password, challenge)

      {:ok, info} ->
        session_from(info)

      {:error, _reason} = error ->
        error
    end
  end

  defp answer_challenge(client, username, password, challenge) do
    response = "#{challenge}-#{md5("#{challenge}-#{password}")}"

    case login_request(client, username: username, response: response) do
      {:ok, %{"SID" => @no_session, "BlockTime" => block_time}} ->
        {:error, %Error{reason: {:login_failed, block_time: String.to_integer(block_time)}}}

      {:ok, info} ->
        session_from(info)

      {:error, _reason} = error ->
        error
    end
  end

  defp session_from(%{"SID" => @no_session}), do: {:error, %Error{reason: :login_failed}}
  defp session_from(%{"SID" => session_id}), do: {:ok, session_id}

  defp login_request(client, params \\ []) do
    case get(client, @login_path, params) do
      {:ok, %{"SessionInfo" => %{"SID" => _} = info}} -> {:ok, info}
      {:ok, body} -> {:error, %Error{reason: {:unexpected_response, body}}}
      {:error, _reason} = error -> error
    end
  end

  defp md5(data) when is_binary(data) do
    utf16 = :unicode.characters_to_binary(data, :utf8, {:utf16, :little})
    Base.encode16(:crypto.hash(:md5, utf16), case: :lower)
  end

  defp get(%__MODULE__{http_client: http_client} = client, path, params) do
    url = build_url(client.base_url, path, params)

    case http_client.get(url, client.request_opts) do
      {:ok, 200, headers, body} ->
        decode_body(headers, body)

      {:ok, status, headers, body} ->
        reason = http_reason(status, params[:sid], params[:ain])
        {:error, %Error{reason: reason, response: {status, headers, body}}}

      {:error, reason} ->
        {:error, %Error{reason: reason}}
    end
  end

  # A status means different things depending on what the request was asking
  # for: only a request that carries a session can have an expired one, and only
  # one that names an actor can fail to find it. Login requests carry neither.
  defp http_reason(403, session_id, _ain) when is_binary(session_id), do: :session_expired
  defp http_reason(403, _session_id, _ain), do: :user_not_authorized
  defp http_reason(400, _session_id, ain) when is_binary(ain), do: :actor_not_found
  defp http_reason(400, _session_id, _ain), do: :bad_request
  defp http_reason(500, _session_id, _ain), do: :internal_error
  defp http_reason(_status, _session_id, _ain), do: :unknown

  defp build_url(base_url, path, params) do
    %URI{} = uri = URI.merge(base_url, path)
    query = if params != [], do: URI.encode_query(params)

    URI.to_string(%URI{uri | query: query})
  end

  # `XmlToMap.naive_map/1` throws on malformed XML, which a captive portal or a
  # truncated response can produce just as easily as a firmware quirk. Catch it
  # so every response leaves this module as an ok/error tuple.
  defp decode_body(headers, body) do
    if body != "" and xml?(headers) do
      {:ok, XmlToMap.naive_map(body)}
    else
      {:ok, String.trim_trailing(body, "\n")}
    end
  catch
    :throw, _reason -> {:error, %Error{reason: {:unexpected_response, body}}}
  end

  defp xml?(headers) do
    case List.keyfind(headers, "content-type", 0) do
      {_, "application/xml" <> _} -> true
      {_, "text/xml" <> _} -> true
      _ -> false
    end
  end
end
