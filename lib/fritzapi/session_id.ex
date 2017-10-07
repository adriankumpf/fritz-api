defmodule Fritzapi.SessionId do
  @moduledoc """
  Implemented according to https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/AVM_Technical_Note_-_Session_ID.pdf
  """

  alias Fritzapi.{FritzBox, Helper}

  @zero_sid "0000000000000000"

  def fetch(username, password, opts) do
    with {:ok, challenge_body} <- FritzBox.get("/login_sid.lua", [], opts),
         {:ok, challenge_resp} <- create_challenge_response(challenge_body, password),
         {:ok, login_body} <- FritzBox.get("/login_sid.lua", [username: username, response: challenge_resp], opts),
         {:ok, session_id} <- parse_login_body(login_body)
    do
      session_id
    else
      {:error, {:already_logged_in, session_id}} ->
        session_id
      err ->
        err
    end
  end

  defp create_challenge_response(
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>" <>
    "<SessionInfo><SID>" <> <<session_id::bytes-size(16)>> <> "</SID>" <>
    "<Challenge>" <> <<challenge::bytes-size(8)>> <> "</Challenge>" <>
    _rest,
    password
  ) do
    case session_id do
      @zero_sid ->
        {:ok, challenge <> "-" <> Helper.md5(challenge <> "-" <> password)}
      _ ->
        {:error, {:already_logged_in, session_id}}
    end
  end
  defp create_challenge_response(_, _) do
    {:error, :invalid_challenge_response}
  end

  defp parse_login_body(
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>" <>
    "<SessionInfo><SID>" <> <<session_id::bytes-size(16)>> <> "</SID>" <>
    _rest
  ) do
    case session_id do
      @zero_sid ->
        {:error, :login_failed}
      _ ->
        {:ok, session_id}
    end
  end
  defp parse_login_body(_) do
    {:error, :invalid_login_body}
  end
end
