defmodule FritzApi.FritzBox do
  @moduledoc false

  alias HTTPoison.{Response, Error}

  @base "http://fritz.box"

  @type opts :: [
    base: String.t,
    ssl: list
  ]

  @type params :: [
    ain: String.t,
    response: String.t,
    sid: String.t,
    switchcmd: String.t,
    username: String.t
  ]

  @spec get(String.t, params, opts) :: {:error, any} | {:ok, String.t}
  def get(path, params, opts) do
    "#{opts[:base] || @base}#{path}"
    |> HTTPoison.get([], [params: params, ssl: opts[:ssl]])
    |> parse_response
  end

  @spec parse_body(String.t) :: {:error, any} | {:ok, String.t}
  defp parse_body(body) do
    case Regex.run(~r/action=".?login.lua"/, body) do
      nil -> {:ok, String.trim_trailing(body, "\n")}
      _ -> {:error, :forbidden}
    end
  end

  @spec parse_response({:ok, Response.t} | {:error, Error.t}) :: {:error, any} | {:ok, String.t}
  defp parse_response({:ok, %Response{status_code: 200, body: body}}), do:
    parse_body(body)
  defp parse_response({:ok, %Response{status_code: 400}}), do:
    {:error, :bad_request}
  defp parse_response({:ok, %Response{status_code: 403}}), do:
    {:error, :forbidden}
  defp parse_response({:ok, %Response{status_code: 500}}), do:
    {:error, :server_error}
  defp parse_response({:ok, %Response{status_code: sc}}), do:
    {:error, {:status_code, sc}}
  defp parse_response({:error, %Error{reason: reason}}), do:
    {:error, reason}
end
