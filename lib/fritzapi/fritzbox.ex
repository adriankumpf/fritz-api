defmodule Fritzapi.FritzBox do
  alias HTTPoison.{Response, Error}

  def get(path, base) do
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
  defp parse_response({:ok, %Response{status_code: 404}}), do:
    {:error, :not_found}
  defp parse_response({:error, %Error{reason: reason}}), do:
    {:error, reason}
end
