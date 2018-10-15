defmodule Web.UserChannelTest do
  use Web.ChannelCase

  test "channel is protected with names" do
    {:ok, socket} = connect(Web.UserSocket, %{"name" => "bob"})
    assert {:ok, _reply, _socket} = join(socket, "user:bob")
    assert {:error, %{}} == join(socket, "user:alice")
  end

  test "users are notified when a new chat with them starts" do
    {:ok, bob_socket} = connect(Web.UserSocket, %{"name" => "bob"})
    {:ok, alice_socket} = connect(Web.UserSocket, %{"name" => "alice"})

    {:ok, _reply, _alice_socket} = subscribe_and_join(alice_socket, "user:alice")
    {:ok, _reply, _bob_socket} = join(bob_socket, "chats:alice:bob")

    assert_push("chat:started", push)
    assert push == %{"with" => "bob"}
  end
end
