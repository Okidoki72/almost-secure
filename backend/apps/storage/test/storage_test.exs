defmodule StorageTest do
  use ExUnit.Case
  alias Storage.Account
  require Storage

  setup do
    Storage.clean()
    :ok
  end

  test "lookup or create account" do
    # try it once
    assert %Account{id: 1, name: "alice"} == Storage.lookup_or_create_account("alice")

    # try it twice
    assert %Account{id: 1, name: "alice"} == Storage.lookup_or_create_account("alice")

    # now bob
    assert %Account{id: 2, name: "bob"} == Storage.lookup_or_create_account("bob")

    # and alice
    assert %Account{id: 1, name: "alice"} == Storage.lookup_or_create_account("alice")

    # and bob again
    assert %Account{id: 2, name: "bob"} == Storage.lookup_or_create_account("bob")
  end

  test "search" do
    # save alice and bob
    assert %Account{id: 1, name: "alice"} == Storage.lookup_or_create_account("alice")
    assert %Account{id: 2, name: "bob"} == Storage.lookup_or_create_account("bob")

    # now search for them
    assert [%Account{id: 1, name: "alice"}] = Storage.search("alice")
    assert [%Account{id: 2, name: "bob"}] = Storage.search("bob")
    assert [] = Storage.search("")
    assert [] = Storage.search("eve")
  end

  test "save identity key" do
    identity_key = "BVHGdlPCzfb/bYNnU5f0vdqamOCz8kEHIO6awQHt/FBr"
    assert %Account{id: 1, name: "alice"} == Storage.lookup_or_create_account("alice")
    assert true == Storage.save_identity_key("alice", identity_key)
    assert identity_key == Storage.identity_key("alice")
  end

  test "save and pop pre keys" do
    pre_keys = [
      Storage._pre_key(id: 1, public_key: "BXdfmfrDv1rmP45Xx2IkugHXwp65aR26JKHk67u/dhx4"),
      Storage._pre_key(id: 2, public_key: "BQfIBzuwCbbXlCYe1k0/PqgPamGwfk0piYzG8rYK4qFy"),
      Storage._pre_key(id: 3, public_key: "BXASB9IQ+QM+WnKU22CiimVeyotW8GxqmG5G3ZT0gRNq")
    ]

    assert %Account{id: 1, name: "alice"} == Storage.lookup_or_create_account("alice")
    assert true == Storage.save_pre_keys("alice", pre_keys)

    assert Storage._pre_key(id: 1, public_key: "BXdfmfrDv1rmP45Xx2IkugHXwp65aR26JKHk67u/dhx4") ==
             Storage.pop_pre_key("alice")

    assert Storage._pre_key(id: 2, public_key: "BQfIBzuwCbbXlCYe1k0/PqgPamGwfk0piYzG8rYK4qFy") ==
             Storage.pop_pre_key("alice")

    assert Storage._pre_key(id: 3, public_key: "BXASB9IQ+QM+WnKU22CiimVeyotW8GxqmG5G3ZT0gRNq") ==
             Storage.pop_pre_key("alice")

    assert nil == Storage.pop_pre_key("alice")
  end

  test "save signed pre key" do
    signed_pre_key =
      Storage._signed_pre_key(
        id: 1,
        public_key: "BZX9JA3via6gilOr6sILYaXqLtd1WQ48/v8VyQo1C79a",
        signature:
          "dFlI8ZkswGWAcvw6xgu1lo70puVzSK4cO7/UAEBn4OFDCdLfjlh7QJhfqfVHiAh6n/eO58SK1QMMLUL059g6Dg=="
      )

    assert %Account{id: 1, name: "alice"} == Storage.lookup_or_create_account("alice")
    assert true == Storage.save_signed_pre_key("alice", signed_pre_key)
    assert signed_pre_key == Storage.signed_pre_key("alice")
  end

  test "save all keys" do
    assert %Account{id: 1, name: "alice"} == Storage.lookup_or_create_account("alice")
    identity_key = "BVHGdlPCzfb/bYNnU5f0vdqamOCz8kEHIO6awQHt/FBr"

    pre_keys = [
      Storage._pre_key(id: 1, public_key: "BXdfmfrDv1rmP45Xx2IkugHXwp65aR26JKHk67u/dhx4"),
      Storage._pre_key(id: 2, public_key: "BQfIBzuwCbbXlCYe1k0/PqgPamGwfk0piYzG8rYK4qFy"),
      Storage._pre_key(id: 3, public_key: "BXASB9IQ+QM+WnKU22CiimVeyotW8GxqmG5G3ZT0gRNq")
    ]

    signed_pre_key =
      Storage._signed_pre_key(
        id: 1,
        public_key: "BZX9JA3via6gilOr6sILYaXqLtd1WQ48/v8VyQo1C79a",
        signature:
          "dFlI8ZkswGWAcvw6xgu1lo70puVzSK4cO7/UAEBn4OFDCdLfjlh7QJhfqfVHiAh6n/eO58SK1QMMLUL059g6Dg=="
      )

    assert true == Storage.save_identity_key("alice", identity_key)
    assert true == Storage.save_pre_keys("alice", pre_keys)
    assert true == Storage.save_signed_pre_key("alice", signed_pre_key)

    assert Storage.account(
             id: 1,
             name: "alice",
             identity_key: identity_key,
             signed_pre_key: signed_pre_key,
             pre_keys: pre_keys
           ) == Storage._account("alice")
  end

  test "lookup non existent identity key" do
    assert_raise ArgumentError, fn ->
      Storage.identity_key("eve")
    end
  end
end
