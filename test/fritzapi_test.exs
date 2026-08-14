defmodule FritzApiTest do
  use FritzApi.Case, async: false

  import ExUnit.CaptureLog

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

  setup_all do
    # Capture the `Application fritz_api exited: :stopped` report
    capture_log(fn -> Application.stop(:fritz_api) end)

    on_exit(fn -> Application.start(:fritz_api) end)

    :ok
  end

  setup do
    Process.register(self(), :fritz_api_test)

    start_supervised!(%{
      id: __MODULE__,
      start: {FritzApi.Application, :start, [nil, []]},
      type: :supervisor
    })

    :ok
  end

  @config [client: TestClient]
  test "allows to return nil from child_spec/1" do
    assert Supervisor.which_children(FritzApi.Supervisor) == []
  end

  @config [client: InspectPoolOptsClient, client_pool_opts: [pool_max_idle_time: 6000]]
  test "passes the :client_pool_opts to child_spec/1" do
    assert_receive {:child_spec, [pool_max_idle_time: 6000]}
  end

  @config [client: TestClient, client_request_opts: [receive_timeout: 11_000]]
  test "passes the :client_request_opts to get/2", %{client: client} do
    mock(fn _url, _query, opts ->
      send(self(), {:req_opts, opts})
      {:ok, 200, [], "Smart Plug"}
    end)

    assert {:ok, "Smart Plug"} = FritzApi.get_switch_name(client, "$ain")

    assert_receive {:req_opts, [receive_timeout: 11_000]}
  end
end
