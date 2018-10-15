if Mix.env() == :dev do
  defmodule Web.StorageController do
    use Web, :controller

    def clean(conn, _params) do
      Storage.clean()
      send_resp(conn, 200, [])
    end
  end
end
