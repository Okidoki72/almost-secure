defmodule Web.ChatChannel do
  use Web, :channel

  def join("chats:" <> sorted_member_names, _params, %{assigns: %{name: me}} = socket) do
    [_, _] = names = :binary.split(sorted_member_names, ":", [:global])
    [other] = Enum.reject(names, fn name -> me == name end)
    Web.Endpoint.broadcast("user:#{other}", "chat:started", %{"with" => me})
    {:ok, socket}
  end

  def handle_in("new:message", %{"data" => data}, socket) when is_binary(data) do
    broadcast_from!(socket, "new:message", %{"data" => data})
    {:reply, :ok, socket}
  end
end
