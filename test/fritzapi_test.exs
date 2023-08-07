defmodule FritzApiTest do
  use FritzApi.Case, async: false

  defmodule InspectPoolOptsClient do
    @behaviour FritzApi.HTTPClient

    @impl true
    def child_spec(pool_opts) do
      send(:fritz_api_test, {:child_spec, pool_opts})
      Finch.child_spec(name: __MODULE__)
    end

    @impl true
    def get(_url, _opts), do: raise("unimplemented!")
  end

  defmodule NoChildSpecTestClient do
    @behaviour FritzApi.HTTPClient

    @impl true
    def child_spec(_pool_opts), do: nil

    @impl true
    def get(_url, _opts), do: raise("unimplemented!")
  end

  setup_all do
    # Temporarily disable logging to suppress `Application fritz_api exited: :stopped` message
    with_log_level(:error, fn ->
      Application.stop(:fritz_api)
    end)

    on_exit(fn ->
      Application.start(:fritz_api)
    end)

    :ok
  end

  setup do
    Process.register(self(), :fritz_api_test)

    start_supervised!(%{
      id: __MODULE__,
      start: {FritzApi.Application, :start, [nil, []]},
      type: :supervisor
    })

    [pid: self()]
  end

  @config [client: NoChildSpecTestClient]
  test "allows to return nil from child_spec/1" do
    refute_receive _
  end

  @config [client: InspectPoolOptsClient, client_pool_opts: [pool_max_idle_time: 6000]]
  test "passes the :client_pool_opts to child_spec/1" do
    assert_receive {:child_spec, [pool_max_idle_time: 6000]}
  end

  @config [client: TestClient, client_request_opts: [receive_timeout: 11_000]]
  test "passes the :client_request_opts to request/5", %{client: client, pid: pid} do
    mock(fn _url, _params, opts ->
      send(pid, {:req_opts, opts})
      {:ok, 200, [], ""}
    end)

    {:ok, _} = FritzApi.get_switch_name(client, "$ain")

    assert_receive {:req_opts, [receive_timeout: 11_000]}
  end
end
