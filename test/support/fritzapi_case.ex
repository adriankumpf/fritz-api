defmodule FritzApi.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      ExUnit.Case.register_attribute(__MODULE__, :logged_in)
      ExUnit.Case.register_attribute(__MODULE__, :config)

      import FritzApi.Case, only: [mock: 1, with_log_level: 2]
    end
  end

  setup tags do
    if config = tags.registered[:config] do
      if tags[:async] do
        raise "@config can only be set with `async: false`"
      end

      for {key, value} <- config do
        Application.put_env(:fritz_api, key, value)
      end

      on_exit(fn ->
        for {key, _value} <- config do
          Application.delete_env(:fritz_api, key)
        end
      end)
    end

    session_id = if tags.registered[:logged_in], do: "$session_id"
    client = FritzApi.Client.new(http_client: TestClient, session_id: session_id)

    {:ok, client: client}
  end

  def mock(fun) do
    Process.put(:get_mock, fn url, opts ->
      uri = URI.parse(url)
      url = put_in(uri.query, nil) |> URI.to_string()

      query =
        case uri.query do
          nil ->
            nil

          _ ->
            URI.query_decoder(uri.query)
            |> Enum.map(fn {key, val} -> {String.to_atom(key), val} end)
        end

      fun.(url, query, opts)
    end)
  end

  def with_log_level(level, fun) do
    original_level = Logger.level()
    Logger.configure(level: level)
    result = fun.()
    Logger.configure(level: original_level)
    result
  end
end
