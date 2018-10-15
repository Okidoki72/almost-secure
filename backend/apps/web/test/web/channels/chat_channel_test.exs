defmodule Web.ChatChannelTest do
  use Web.ChannelCase

  setup do
    Storage.clean()

    {:ok, socket} = connect(Web.UserSocket, %{"name" => "bob"})
    {:ok, _reply, socket} = subscribe_and_join(socket, "chats:alice:bob")

    {:ok, socket: socket}
  end

  test "it works", %{socket: socket} do
    message =
      "AzMIARIhBVoy5BgUDowZoVL7xeIdVKkMsC6C6PF/SpD0GhSd4Ds/GiEFJ7ZYITYg7j2U/kG0JTbR77Svpn4lT+ZAuY4V/GeQ5CIiQjMKIQVBJqfGIywe6cMK+g45LNtyG+Hlhilx5dMEjKEKaAYTWBAAGAAiEAcyc0+TVmDcYuSnhqiFZcTk1ubwiHqZpSidRTAB"

    ref = push(socket, "new:message", %{"data" => message})

    assert_reply(ref, :ok, reply)
    assert reply == %{}

    assert_broadcast("new:message", broadcast)
    assert broadcast == %{"data" => message}
  end
end
