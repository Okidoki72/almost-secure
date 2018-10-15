defmodule Web.SearchChannel do
  use Web, :channel
  alias Storage.Account

  def join("search", _params, socket) do
    {:ok, socket}
  end

  def handle_in("search", %{"query" => query}, socket) when is_binary(query) do
    users =
      query
      |> Storage.search()
      |> Enum.map(fn %Account{name: name} ->
        %{"name" => name}
      end)

    {:reply, {:ok, %{"users" => users}}, socket}
  end
end
