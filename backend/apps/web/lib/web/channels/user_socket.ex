defmodule Web.UserSocket do
  use Phoenix.Socket

  channel("search", Web.SearchChannel)
  channel("chats:*", Web.ChatChannel)
  channel("user:*", Web.UserChannel)

  transport(:websocket, Phoenix.Transports.WebSocket)

  def connect(%{"name" => name}, socket) do
    {:ok, assign(socket, :name, name)}
  end

  def id(socket) do
    socket.assigns.name
  end
end
