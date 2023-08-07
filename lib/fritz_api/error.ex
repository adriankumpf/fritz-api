defmodule FritzApi.Error do
  @moduledoc """
  A FritzApi Error
  """

  alias FritzApi.HTTPClient

  @type response :: {HTTPClient.status(), HTTPClient.headers(), HTTPClient.body()}

  @type t :: %__MODULE__{
          reason: term,
          response: response | nil
        }

  defexception [:reason, :response]

  @impl true
  def message(%__MODULE__{reason: reason}) do
    to_string(reason)
  end
end
