defmodule FritzApi.Error do
  @moduledoc """
  A FritzApi Error
  """

  alias FritzApi.HTTPClient

  @typedoc "The HTTP response that caused the error, if there was one."
  @type response :: {HTTPClient.status(), HTTPClient.headers(), HTTPClient.body()}

  @typedoc """
  Why the request failed.

  Besides the reasons listed here, it can be any term returned by the HTTP
  client, for example `%Finch.TransportError{reason: :timeout}`.
  """
  @type reason ::
          :session_expired
          | :user_not_authorized
          | :actor_not_found
          | :bad_request
          | :internal_error
          | :unknown
          | :login_failed
          | {:login_failed, [block_time: non_neg_integer]}
          | {:unexpected_response, term}
          | term

  @type t :: %__MODULE__{
          reason: reason,
          response: response | nil
        }

  defexception [:reason, :response]

  @impl true
  def message(%__MODULE__{reason: reason}), do: format(reason)

  defp format(reason) when is_atom(reason), do: to_string(reason)
  defp format({:login_failed, block_time: 0}), do: "login failed"

  defp format({:login_failed, block_time: seconds}) do
    "login failed, blocked for #{seconds} seconds"
  end

  defp format({:unexpected_response, body}), do: "unexpected response: #{inspect(body)}"
  defp format(%{__exception__: true} = exception), do: Exception.message(exception)
  defp format(reason), do: inspect(reason)
end
