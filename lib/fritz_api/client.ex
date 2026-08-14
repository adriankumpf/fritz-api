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
  @command_path "/webservices/homeautoswitch.lua"

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
    case get(client, "/login_sid.lua") do
      {:ok, %{"SessionInfo" => %{"SID" => "0000000000000000", "Challenge" => challenge}}}
      when is_binary(challenge) ->
        challenge_resp = "#{challenge}-#{md5("#{challenge}-#{password}")}"

        case get(client, "/login_sid.lua", username: username, response: challenge_resp) do
          {:ok, %{"SessionInfo" => %{"SID" => "0000000000000000", "BlockTime" => block_time}}} ->
            reason = {:login_failed, block_time: String.to_integer(block_time)}
            {:error, %Error{reason: reason}}

          {:ok, %{"SessionInfo" => %{"SID" => session_id}}} ->
            {:ok, session_id}

          {:error, reason} ->
            {:error, reason}
        end

      {:ok, %{"SessionInfo" => %{"SID" => session_id}}} ->
        {:ok, session_id}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp md5(data) when is_binary(data) do
    data
    |> :unicode.characters_to_binary(:utf8, {:utf16, :little})
    |> (&:crypto.hash(:md5, &1)).()
    |> Base.encode16(case: :lower)
  end

  defp get(%__MODULE__{http_client: http_client} = client, path, params \\ []) do
    url = build_url(client.base_url, path, params)

    case http_client.get(url, client.request_opts) do
      {:ok, 200, headers, body} ->
        {:ok, maybe_decode_body(headers, body)}

      {:ok, status, headers, body} ->
        ain = params[:ain]
        sid = params[:sid]

        reason =
          case status do
            403 when is_binary(sid) -> :session_expired
            403 -> :user_not_authorized
            400 when is_binary(ain) -> :actor_not_found
            400 -> :bad_request
            500 -> :internal_error
            _ -> :unknown
          end

        {:error, %Error{reason: reason, response: {status, headers, body}}}

      {:error, reason} ->
        {:error, %Error{reason: reason}}
    end
  end

  defp build_url(base_url, path, params) do
    query =
      case params do
        [] -> nil
        _ -> URI.encode_query(params)
      end

    base_url
    |> URI.merge(path)
    |> Map.put(:query, query)
    |> URI.to_string()
  end

  defp maybe_decode_body(headers, body) do
    cond do
      decodable_body?(body) and decodable_content_type?(headers) -> XmlToMap.naive_map(body)
      is_binary(body) -> String.trim_trailing(body, "\n")
      true -> body
    end
  end

  defp decodable_body?(body) when is_binary(body) and body != "", do: true
  defp decodable_body?(body) when is_list(body) and body != [], do: true
  defp decodable_body?(_body), do: false

  defp decodable_content_type?(headers) do
    case List.keyfind(headers, "content-type", 0) do
      {_, "application/xml" <> _} -> true
      {_, "text/xml" <> _} -> true
      _ -> false
    end
  end
end
