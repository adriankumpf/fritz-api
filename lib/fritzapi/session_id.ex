defmodule Fritzapi.SessionId do

  alias Fritzapi.{FritzBox, Options}

  def fetch(username, password, %Options{base: base}) do
    with {:ok, challenge_body} <- FritzBox.get("/login_sid.lua", base),
         {:ok, challenge_resp} <- create_challenge_response(challenge_body, password),
         {:ok, login_body} <- FritzBox.get("/login_sid.lua?username=" <> username <> "&response=" <> challenge_resp, base),
         {:ok, session_id} <- parse_login_body(login_body)
    do
      session_id
    end
  end

  defp md5(data) do
    data
    |> :unicode.characters_to_binary(:utf8, {:utf16, :little})
    |> (&:crypto.hash(:md5, &1)).()
    |> Base.encode16(case: :lower)
  end

  defp create_challenge_response(
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>" <>
    "<SessionInfo><SID>0000000000000000</SID>" <>
    "<Challenge>" <> <<challenge::bytes-size(8)>> <> "</Challenge>" <>
    "<BlockTime>0</BlockTime><Rights></Rights></SessionInfo>\n",
      password
  ), do:
    {:ok, challenge <> "-" <> md5(challenge <> "-" <> password)}
  defp create_challenge_response(_, _), do:
    {:error, :invalid_challenge_response}

  defp parse_login_body(
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>" <>
    "<SessionInfo><SID>0000000000000000</SID>" <>
    _rest
  ), do:
    {:error, :login_failed}
  defp parse_login_body(
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>" <>
    "<SessionInfo><SID>" <> <<session_id::bytes-size(16)>> <> "</SID>" <>
    _rest
  ), do:
    {:ok, session_id}
  defp parse_login_body(_), do:
    {:error, :invalid_login_body}
end
