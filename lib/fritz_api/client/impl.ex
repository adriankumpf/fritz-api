defmodule FritzApi.Client.Impl do
  @moduledoc false

  alias FritzApi.{SessionId, Commands}

  def init([username: username, password: password, opts: opts]) do
    {:ok, sid} = SessionId.fetch(username, password, opts)
    %{sid: sid, username: username, password: password, opts: opts}
  end

  def executte_command(cmd, ain, %{sid: sid, username: user, password: pw, opts: opts} = state) do
    case apply(Commands, cmd, remove_nil([sid, ain, opts])) do
      :ok ->
        {:ok, state}
      {:ok, val} ->
        {{:ok, val}, state}
      {:error, :forbidden} ->
        {:ok, new_sid} = FritzApi.get_session_id(user, pw, opts)
        executte_command(cmd, ain, %{state | sid: new_sid})
      {:error, _} = err ->
        {err, state}
    end
  end

  defp remove_nil(list) do
    Enum.filter(list, &(&1 !== nil))
  end

end
