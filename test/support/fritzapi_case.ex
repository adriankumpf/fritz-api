defmodule FritzApi.Case do
  @moduledoc false

  use ExUnit.CaseTemplate

  @session_id "$session_id"
  @command_url "http://fritz.box/webservices/homeautoswitch.lua"
  @login_url "http://fritz.box/login_sid.lua"

  using do
    quote do
      ExUnit.Case.register_attribute(__MODULE__, :logged_in)
      ExUnit.Case.register_attribute(__MODULE__, :config)

      @session_id unquote(@session_id)
      @command_url unquote(@command_url)
      @login_url unquote(@login_url)

      import FritzApi.Case, only: [mock: 1, mock_command: 2]
    end
  end

  setup tags do
    if config = tags.registered[:config] do
      if tags[:async] do
        raise "@config can only be set with `async: false`"
      end

      Application.put_all_env(fritz_api: config)

      on_exit(fn ->
        for {key, _value} <- config, do: Application.delete_env(:fritz_api, key)
      end)
    end

    session_id = if tags.registered[:logged_in], do: @session_id

    {:ok, client: FritzApi.Client.new(http_client: TestClient, session_id: session_id)}
  end

  @doc """
  Answers every request with `fun`, called as `fun.(url, query, opts)`.

  `url` has the query string stripped; `query` is that query string decoded into
  a keyword list, or `nil` if there was none.
  """
  def mock(fun) do
    Process.put(:get_mock, fn url, opts ->
      uri = URI.parse(url)
      fun.(URI.to_string(%URI{uri | query: nil}), decode_query(uri.query), opts)
    end)
  end

  defp decode_query(nil), do: nil

  defp decode_query(query) do
    for {key, value} <- URI.query_decoder(query), do: {String.to_atom(key), value}
  end

  @doc """
  Answers `cmd` for a logged in client.

  Takes either a map from AIN to raw response body, or a function called with
  the command's remaining query params (`:ain` included) returning that body.
  """
  def mock_command(cmd, fun) when is_function(fun, 1) do
    mock(fn @command_url, [{:switchcmd, ^cmd}, {:sid, @session_id} | params], _opts ->
      {:ok, 200, [], fun.(params)}
    end)
  end

  def mock_command(cmd, responses_by_ain) when is_map(responses_by_ain) do
    mock_command(cmd, &Map.fetch!(responses_by_ain, &1[:ain]))
  end
end
