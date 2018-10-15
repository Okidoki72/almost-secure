# defmodule Web.Socket do
#   @behaviour :cowboy_websocket_handler

#   def init(_, _req, _opts) do
#     {:upgrade, :protocol, :cowboy_websocket}
#   end

#   # now online
#   def websocket_init(_type, req, _opts) do
#     Logger.info("Socket starting")
#     {:ok, req, %State{status: "inactive"}}
#   end

#   def websocket_handle({:text, message}, req, state) do
#     message
#     |> Poison.decode!()
#     |> handle()
#     |> case do
#       {:reply, reply} ->
#         {:reply, {:text, Poison.encode!(reply)}, req, state}

#       :noreply ->
#         {:ok, req, state}
#     end
#   end

#   def websocket_info(text, state) do
#     {:reply, {:text, text}, state}
#   end

#   defp handle(%{"topic" => "search", "query" => query}) when is_binary(query) do
#     users =
#       query
#       |> Storage.search()
#       |> Enum.map(fn %Account{name: name} ->
#         %{"name" => name}
#       end)

#     {:reply, users}
#   end

#   defp handle(%{"topic" => ""}) do

#   end
# end
