defmodule Fritzapi do
  @moduledoc """
  Documentation for Fritzapi.
  """

  alias Fritzapi.Options

  def get_session_id(username, password, opts \\ %Options{}) do
    Fritzapi.SessionId.fetch(username, password, opts)
  end

  def get_device_list_infos(sid, opts \\ %Options{}) do
    Fritzapi.DeviceListInfos.fetch(sid, opts)
  end

end
