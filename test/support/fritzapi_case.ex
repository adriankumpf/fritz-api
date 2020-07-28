defmodule FritzApi.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Tesla.Mock
    end
  end

  setup tags do
    opts =
      if tags[:logged_in] do
        [session_id: "$session_id"]
      else
        []
      end

    {:ok, client: FritzApi.Client.new([{:adapter, Tesla.Mock} | opts])}
  end
end
