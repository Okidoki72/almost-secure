defmodule Web.UserChannel do
  use Web, :channel

  def join("user:" <> name, _params, %{assigns: %{name: name}} = socket) do
    {:ok, socket}
  end

  def join(_topic, _params, _socket) do
    {:error, %{}}
  end
end
