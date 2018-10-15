defmodule Web.SearchChannelTest do
  use Web.ChannelCase

  setup do
    Storage.clean()

    {:ok, socket} = connect(Web.UserSocket, %{"name" => "alice"})
    {:ok, _reply, socket} = subscribe_and_join(socket, "search")

    {:ok, socket: socket}
  end

  describe "search" do
    setup :create_alice_and_bob

    test "search", %{socket: socket} do
      ref = push(socket, "search", %{"query" => "alice"})
      assert_reply(ref, :ok, %{"users" => [%{"name" => "alice"}]})

      ref = push(socket, "search", %{"query" => "bob"})
      assert_reply(ref, :ok, %{"users" => [%{"name" => "bob"}]})

      ref = push(socket, "search", %{"query" => "eve"})
      assert_reply(ref, :ok, %{"users" => []})

      # ref = push(socket, "search", %{"query" => 123})
      # assert_reply(ref, :ok, %{"users" => []})
    end
  end

  defp create_alice_and_bob(_context) do
    Storage.lookup_or_create_account("alice")
    Storage.lookup_or_create_account("bob")

    :ok
  end
end
