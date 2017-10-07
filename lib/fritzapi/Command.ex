defmodule Fritzapi.Command do
  alias Fritzapi.{FritzBox, Helper, Params}

  @path "/webservices/homeautoswitch.lua"

  def execute(cmd, sid, opts) do
    FritzBox.get(@path, %Params{sid: sid, switchcmd: cmd}, opts)
    |> parse_response
  end
  def execute(cmd, ain, sid, opts) do
    FritzBox.get(@path, %Params{sid: sid, ain: ain, switchcmd: cmd}, opts)
    |> parse_response
  end

  defp parse_response({:ok, resp}), do: String.trim_trailing(resp, "\n")
  defp parse_response(err), do: err
end
