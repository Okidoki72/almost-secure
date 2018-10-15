defmodule Web.AccountView do
  use Web, :view

  def render("account.json", %{
        account: %Storage.Account{id: id, name: name}
      }) do
    %{
      "id" => id,
      "name" => name
    }
  end
end
