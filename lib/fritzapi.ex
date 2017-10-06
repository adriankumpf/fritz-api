defmodule Crypto do
  def md5(data) do
    data
    |> :unicode.characters_to_binary(:utf8, {:utf16, :little})
    |> (&:crypto.hash(:md5, &1)).()
    |> Base.encode16(case: :lower)
  end
end

defmodule Fritzapi.Opts do
  defstruct sid: nil, switchmd: nil, ain: nil

  def to_string(%__MODULE__{} = opts) do
    opts
    |> Map.from_struct
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})
    |> URI.encode_query
  end
end

defmodule Fritzapi do
  @moduledoc """
  Documentation for Fritzapi.
  """

  alias HTTPoison.{Response, Error}
  alias Fritzapi.Opts

  @default_base "http://fritz.box"

  @doc """
  Hello world.

  ## Examples

  iex> Fritzapi.hello
  :world

  """
  def hello do
    :world
  end

  def get_session_id(username, password) do
    with {:ok, challenge_body} <- execute_command("/login_sid.lua"),
         {:ok, challenge_resp} <- create_challenge_response(challenge_body, password),
         {:ok, login_body} <- execute_command("/login_sid.lua?username=" <> username <> "&response=" <> challenge_resp),
         {:ok, session_id} <- parse_login_body(login_body)
    do
      session_id
    end
  end

  defp create_challenge_response(
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>" <>
    "<SessionInfo><SID>0000000000000000</SID>" <>
    "<Challenge>" <> <<challenge::bytes-size(8)>> <> "</Challenge>" <>
    "<BlockTime>0</BlockTime><Rights></Rights></SessionInfo>\n",
      password
  ) do
    {:ok, challenge <> "-" <> Crypto.md5(challenge <> "-" <> password)}
  end
  defp create_challenge_response(_, _) do
    {:error, :invalid_challenge_response}
  end

  defp parse_login_body(
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>" <>
    "<SessionInfo><SID>0000000000000000</SID>" <>
    _rest
  ) do
    {:error, :login_failed}
  end
  defp parse_login_body(
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>" <>
    "<SessionInfo><SID>" <> <<session_id::bytes-size(16)>> <> "</SID>" <>
    _rest
  ) do
    {:ok, session_id}
  end
  defp create_challenge_response(_, _) do
    {:error, :invalid_login_body}
  end

  def execute_command(path, %Opts{} = opts \\ %Opts{}) do
    request(path <> Opts.to_string(opts))
  end

  def request(path) do
    case HTTPoison.get(@default_base <> path) do
      {:ok, %Response{status_code: 200, body: body}} ->
        case Regex.run(~r/action=".?login.lua"/, body) do
          nil -> {:ok, body}
          _ -> {:error, :forbidden}
        end
      {:ok, %Response{status_code: 404, body: body}} ->
        {:error, :not_found}
      {:ok, %Response{status_code: 403}} ->
        {:error, :forbidden}
      {:error, %Error{reason: reason}} ->
        {:error, :reason}
    end
  end

end
