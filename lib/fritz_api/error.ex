defmodule FritzApi.Error do
  @moduledoc """
  A FritzApi Error
  """

  @type t :: %__MODULE__{
          reason: term,
          env: Tesla.Env.t() | nil
        }

  defexception [:reason, :env]

  @impl true
  def message(%__MODULE__{reason: reason}) do
    to_string(reason)
  end
end
