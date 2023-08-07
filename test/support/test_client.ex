defmodule TestClient do
  @behaviour FritzApi.HTTPClient

  @impl true
  def child_spec(_pool_opts), do: nil

  @impl true
  def get(url, opts), do: Process.get(:get_mock, &default_mock/2).(url, opts)

  defp default_mock(url, opts) do
    raise "get(#{inspect(url)}, #{inspect(opts)} is not mocked! Call mock/1"
  end
end
