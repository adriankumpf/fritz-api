defmodule FritzApi.Middleware.DecodeXML do
  @moduledoc false

  @behaviour Tesla.Middleware

  @impl Tesla.Middleware
  def call(env, next, _opts) do
    with {:ok, env} <- Tesla.run(env, next) do
      if decodable_body?(env) and decodable_content_type?(env) do
        {:ok, %Tesla.Env{env | body: XmlToMap.naive_map(env.body)}}
      else
        {:ok, env}
      end
    end
  end

  defp decodable_body?(%{body: body}) when is_binary(body) and body != "", do: true
  defp decodable_body?(%{body: body}) when is_list(body) and body != [], do: true
  defp decodable_body?(%{body: _body}), do: false

  defp decodable_content_type?(env) do
    case Tesla.get_header(env, "content-type") do
      "application/xml" <> _ -> true
      "text/xml" <> _ -> true
      _ -> false
    end
  end
end
