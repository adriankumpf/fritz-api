defmodule FritzApi.SessionId do
  @moduledoc false

  alias FritzApi.SessionId.Crypto
  alias FritzApi.FritzBox

  @zero_sid "0000000000000000"

  @spec fetch(String.t(), String.t(), FritzBox.opts()) :: {:error, any} | {:ok, String.t()}
  def fetch(username, password, opts) do
    with {:ok, challenge_body} <- FritzBox.get("/login_sid.lua", [], opts),
         {:ok, challenge_resp} <- create_reponse(challenge_body, password),
         {:ok, login_body} <- login(username, challenge_resp, opts),
         {:ok, session_id} <- parse_login_body(login_body) do
      {:ok, session_id}
    else
      {:error, {:already_logged_in, session_id}} ->
        {:ok, session_id}

      err ->
        err
    end
  end

  @spec login(String.t(), String.t(), FritzBox.opts()) :: {:error, any} | {:ok, String.t()}
  defp login(username, response, opts) do
    FritzBox.get("/login_sid.lua", [username: username, response: response], opts)
  end

  @spec create_reponse(String.t(), String.t()) :: {:error, any} | {:ok, String.t()}
  defp create_reponse(
         ~s(<?xml version="1.0" encoding="utf-8"?>) <>
           "<SessionInfo><SID>" <>
           <<session_id::bytes-size(16)>> <>
           "</SID>" <> "<Challenge>" <> <<challenge::bytes-size(8)>> <> "</Challenge>" <> _rest,
         password
       ) do
    case session_id do
      @zero_sid ->
        {:ok, challenge <> "-" <> Crypto.md5(challenge <> "-" <> password)}

      _ ->
        {:error, {:already_logged_in, session_id}}
    end
  end

  defp create_reponse(_, _) do
    {:error, :invalid_challenge_response}
  end

  @spec parse_login_body(String.t()) :: {:error, any} | {:ok, String.t()}
  defp parse_login_body(
         ~s(<?xml version="1.0" encoding="utf-8"?>) <>
           "<SessionInfo><SID>" <> <<session_id::bytes-size(16)>> <> "</SID>" <> rest
       ) do
    case session_id do
      @zero_sid ->
        {:error, {:login_failed, block_time: get_blocktime(rest)}}

      _ ->
        {:ok, session_id}
    end
  end

  defp parse_login_body(_) do
    {:error, :invalid_login_body}
  end

  defp get_blocktime(xml) do
    [[_, time_str]] = Regex.scan(~r/<BlockTime>(\d+)<\/BlockTime>/, xml)
    {time, _} = Integer.parse(time_str)
    time
  end
end
