defmodule Fritzapi.FritzBox do
  alias HTTPoison.{Response, Error}
  alias Fritzapi.{Options, Params}

  def get(path, %Params{} = params, %Options{} = opts) do
    get(path <> "?" <> Params.encode(params), opts)
  end
  def get(path, %Options{base: base}) do
    (base <> path)
    |> HTTPoison.get
    |> parse_response
  end

  defp parse_body(body) do
    case Regex.run(~r/action=".?login.lua"/, body) do
      nil -> {:ok, body}
      _ -> {:error, :forbidden}
    end
  end

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
