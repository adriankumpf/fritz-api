defmodule FritzApi.Client do
  @moduledoc """
  A FritzApi API Client
  """

  alias FritzApi.Error

  @type t :: %__MODULE__{
          tesla_client: Tesla.Client.t(),
          base_url: String.t(),
          session_id: FritzApi.session_id()
        }

  @enforce_keys [:tesla_client, :base_url]
  defstruct [:tesla_client, :base_url, :session_id]

  @base_url "http://fritz.box"
  @adapter {Tesla.Adapter.Hackney, pool: :default}

  @doc """
  Creates a new FritzApi API client.

  ## Options

    * `:base_url` - the base URL for all endpoints (default: `#{@base_url}`)
    * `:adapter` - the [Tesla adapter](https://hexdoks.pm/tesla/readme.html)
    for the API client (default: `#{inspect(@adapter)}`)
    * `:session_id` - a session ID (see `FritzApi.get_session_id/3`)

  ## Examples

      iex> client = FritzApi.Client.new()
      %FritzApi.Client{}

  """
  @spec new(Keyword.t()) :: t
  def new(opts \\ []) do
    {adapter, opts} = Keyword.pop(opts, :adapter, @adapter)
    {base_url, opts} = Keyword.pop(opts, :base_url, @base_url)
    {session_id, opts} = Keyword.pop(opts, :session_id)

    middlewares = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Opts, opts},
      FritzApi.Middleware.DecodeXML
    ]

    tesla_client = Tesla.client(middlewares, adapter)

    %__MODULE__{tesla_client: tesla_client, base_url: base_url, session_id: session_id}
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
  @spec login(t, String.t(), String.t()) :: {:ok, t} | {:error, Error.t()}
  def login(%__MODULE__{} = client, username, password)
      when is_binary(username) and is_binary(password) do
    with {:ok, session_id} <- FritzApi.get_session_id(client, username, password) do
      {:ok, %__MODULE__{client | session_id: session_id}}
    end
  end
end
