defmodule Web.AccountControllerTest do
  use Web.ConnCase

  setup do
    Storage.clean()
    :ok
  end

  test "register", %{conn: conn} do
    conn = post(conn, "/register", %{"name" => "alice"})
    assert json_response(conn, 200) == %{"id" => 1, "name" => "alice"}

    conn = post(conn, "/register", %{"name" => "bob"})
    assert json_response(conn, 200) == %{"id" => 2, "name" => "bob"}

    conn = post(conn, "/register", %{"name" => "alice"})
    assert json_response(conn, 200) == %{"id" => 1, "name" => "alice"}
  end

  describe "upload" do
    setup :create_alice

    test "upload identity key", %{conn: conn} do
      conn =
        post(conn, "/upload", %{
          "name" => "alice",
          "identity_key" => "BVHGdlPCzfb/bYNnU5f0vdqamOCz8kEHIO6awQHt/FBr"
        })

      assert conn.status == 200
    end

    test "upload pre keys", %{conn: conn} do
      conn =
        post(conn, "/upload", %{
          "name" => "alice",
          "pre_keys" => [
            %{"id" => 1, "public_key" => "BXdfmfrDv1rmP45Xx2IkugHXwp65aR26JKHk67u/dhx4"},
            %{"id" => 2, "public_key" => "BQfIBzuwCbbXlCYe1k0/PqgPamGwfk0piYzG8rYK4qFy"},
            %{"id" => 3, "public_key" => "BXASB9IQ+QM+WnKU22CiimVeyotW8GxqmG5G3ZT0gRNq"}
          ]
        })

      assert conn.status == 200
    end

    test "upload signed pre key", %{conn: conn} do
      conn =
        post(conn, "/upload", %{
          "name" => "alice",
          "signed_pre_key" => %{
            "id" => 1,
            "public_key" => "BZX9JA3via6gilOr6sILYaXqLtd1WQ48/v8VyQo1C79a",
            "signature" =>
              "dFlI8ZkswGWAcvw6xgu1lo70puVzSK4cO7/UAEBn4OFDCdLfjlh7QJhfqfVHiAh6n/eO58SK1QMMLUL059g6Dg=="
          }
        })

      assert conn.status == 200
    end

    test "upload all and then request a pre key bundle", %{conn: conn} do
      conn =
        post(conn, "/upload", %{
          "name" => "alice",
          "identity_key" => "BVHGdlPCzfb/bYNnU5f0vdqamOCz8kEHIO6awQHt/FBr"
        })

      assert conn.status == 200

      conn =
        post(conn, "/upload", %{
          "name" => "alice",
          "pre_keys" => [
            %{"id" => 1, "public_key" => "BXdfmfrDv1rmP45Xx2IkugHXwp65aR26JKHk67u/dhx4"},
            %{"id" => 2, "public_key" => "BQfIBzuwCbbXlCYe1k0/PqgPamGwfk0piYzG8rYK4qFy"},
            %{"id" => 3, "public_key" => "BXASB9IQ+QM+WnKU22CiimVeyotW8GxqmG5G3ZT0gRNq"}
          ]
        })

      assert conn.status == 200

      conn =
        post(conn, "/upload", %{
          "name" => "alice",
          "signed_pre_key" => %{
            "id" => 1,
            "public_key" => "BZX9JA3via6gilOr6sILYaXqLtd1WQ48/v8VyQo1C79a",
            "signature" =>
              "dFlI8ZkswGWAcvw6xgu1lo70puVzSK4cO7/UAEBn4OFDCdLfjlh7QJhfqfVHiAh6n/eO58SK1QMMLUL059g6Dg=="
          }
        })

      assert conn.status == 200

      conn = post(conn, "/pre_key_bundle", %{"name" => "alice"})

      assert json_response(conn, 200) == %{
               "registration_id" => 1,
               "pre_key" => %{
                 "id" => 1,
                 "public_key" => "BXdfmfrDv1rmP45Xx2IkugHXwp65aR26JKHk67u/dhx4"
               },
               "signed_pre_key" => %{
                 "id" => 1,
                 "public_key" => "BZX9JA3via6gilOr6sILYaXqLtd1WQ48/v8VyQo1C79a",
                 "signature" =>
                   "dFlI8ZkswGWAcvw6xgu1lo70puVzSK4cO7/UAEBn4OFDCdLfjlh7QJhfqfVHiAh6n/eO58SK1QMMLUL059g6Dg=="
               },
               "identity_key" => "BVHGdlPCzfb/bYNnU5f0vdqamOCz8kEHIO6awQHt/FBr"
             }
    end
  end

  defp create_alice(%{conn: conn}) do
    {:ok, conn: post(conn, "/register", %{"name" => "alice"})}
  end
end
