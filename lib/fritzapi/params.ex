defmodule Fritzapi.Params do
  defstruct [
    ain: nil,
    param: nil,
    response: nil,
    sid: nil,
    switchcmd: nil,
    username: nil
  ]

  alias Fritzapi.Helper

  def encode(%__MODULE__{} = params) do
    params
    |> Map.from_struct
    |> Helper.remove_nil_values
    |> URI.encode_query
  end
end
