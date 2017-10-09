defmodule FritzApi.SessionId.Crypto do
  @moduledoc false

  @spec md5(String.t) :: String.t
  def md5(data) do
    data
    |> :unicode.characters_to_binary(:utf8, {:utf16, :little})
    |> (&:crypto.hash(:md5, &1)).()
    |> Base.encode16(case: :lower)
  end
end
