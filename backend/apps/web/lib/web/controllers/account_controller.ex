defmodule Web.AccountController do
  use Web, :controller
  require Storage

  def create(conn, %{"name" => name}) when is_binary(name) do
    render(conn, "account.json", account: Storage.lookup_or_create_account(name))
  end

  def upload(conn, %{"name" => name, "identity_key" => identity_key})
      when is_binary(name) and is_binary(identity_key) do
    true = Storage.save_identity_key(name, identity_key)
    send_resp(conn, 200, [])
  end

  def upload(conn, %{"name" => name, "pre_keys" => pre_keys})
      when is_binary(name) and is_list(pre_keys) do
    pre_keys =
      Enum.map(pre_keys, fn %{"id" => id, "public_key" => public_key} ->
        Storage._pre_key(id: id, public_key: public_key)
      end)

    true = Storage.save_pre_keys(name, pre_keys)
    send_resp(conn, 200, [])
  end

  def upload(conn, %{
        "name" => name,
        "signed_pre_key" => %{"id" => id, "public_key" => public_key, "signature" => signature}
      })
      when is_binary(name) do
    signed_pre_key = Storage._signed_pre_key(id: id, public_key: public_key, signature: signature)
    true = Storage.save_signed_pre_key(name, signed_pre_key)
    send_resp(conn, 200, [])
  end

  def pre_key_bundle(conn, %{"name" => name}) when is_binary(name) do
    Storage._pre_key(id: pre_key_id, public_key: public_pre_key) = Storage.pop_pre_key(name)

    Storage._signed_pre_key(
      id: signed_pre_key_id,
      public_key: public_signed_pre_key,
      signature: signature
    ) = Storage.signed_pre_key(name)

    json(conn, %{
      "registration_id" => Storage.registration_id(name),
      "pre_key" => %{
        "id" => pre_key_id,
        "public_key" => public_pre_key
      },
      "identity_key" => Storage.identity_key(name),
      "signed_pre_key" => %{
        "id" => signed_pre_key_id,
        "public_key" => public_signed_pre_key,
        "signature" => signature
      }
    })
  end
end
