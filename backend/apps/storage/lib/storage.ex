defmodule Storage do
  @moduledoc "Serves as a basic in-memory storage for this demo"

  use GenServer
  alias Storage.Account

  @accounts Storage.Accounts
  @messages Storage.Messages

  require Record

  Record.defrecord(:account, [:name, :id, :identity_key, :signed_pre_key, :pre_keys])

  @type account ::
          record(:account,
            name: String.t(),
            id: pos_integer,
            identity_key: binary,
            signed_pre_key: _signed_pre_key,
            pre_keys: [_pre_key]
          )

  Record.defrecord(:_pre_key, [:id, :public_key])

  @type _pre_key ::
          record(:_pre_key,
            id: pos_integer,
            public_key: binary
          )

  Record.defrecord(:_signed_pre_key, [:id, :public_key, :signature])

  @type _signed_pre_key ::
          record(:_signed_pre_key,
            id: pos_integer,
            public_key: binary,
            signature: binary
          )

  defmacrop position(field) do
    quote(do: account(unquote(field)) + 1)
  end

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # NOTE: not atomic
  @spec lookup_or_create_account(String.t()) :: Account.t()
  def lookup_or_create_account(name) do
    case :ets.lookup(@accounts, name) do
      [account(name: ^name, id: id)] -> %Account{id: id, name: name}
      [] -> %Account{id: GenServer.call(__MODULE__, {:create_account, name}), name: name}
    end
  end

  @spec search(String.t()) :: [Account.t()]
  def search(name) do
    case :ets.lookup(@accounts, name) do
      [] ->
        []

      results ->
        Enum.map(results, fn account(name: name, id: id) ->
          %Account{id: id, name: name}
        end)
    end
  end

  @spec registration_id(String.t()) :: pos_integer
  def registration_id(name) do
    :ets.lookup_element(@accounts, name, position(:id))
  end

  @spec save_identity_key(String.t(), binary) :: true
  def save_identity_key(name, identity_key) do
    GenServer.call(__MODULE__, {:save_identity_key, name, identity_key})
  end

  @spec identity_key(String.t()) :: binary
  def identity_key(name) do
    :ets.lookup_element(@accounts, name, position(:identity_key))
  end

  @spec save_pre_keys(String.t(), [_pre_key]) :: true
  def save_pre_keys(name, pre_keys) do
    GenServer.call(__MODULE__, {:save_pre_keys, name, pre_keys})
  end

  @spec pop_pre_key(String.t()) :: _pre_key | nil
  def pop_pre_key(name) do
    GenServer.call(__MODULE__, {:pop_pre_key, name})
  end

  @spec prekeys_left(String.t()) :: non_neg_integer
  def prekeys_left(name) do
    @accounts
    |> :ets.lookup_element(name, position(:pre_keys))
    |> length()
  end

  @spec save_signed_pre_key(String.t(), _signed_pre_key) :: true
  def save_signed_pre_key(name, signed_pre_key) do
    GenServer.call(__MODULE__, {:save_signed_pre_key, name, signed_pre_key})
  end

  @spec signed_pre_key(String.t()) :: _signed_pre_key
  def signed_pre_key(name) do
    :ets.lookup_element(@accounts, name, position(:signed_pre_key))
  end

  # @spec leave_message(chat_id :: binary, message :: binary) :: true
  # def leave_message(message, from, to) do
  #   GenServer.call(__MODULE__, {:store_message, message, from, to})
  # end

  # @spec collect_messages(chat_id :: binary, name :: binary) :: [message :: binary]
  # def collect_messages(name) do
  #   GenServer.call(__MODULE__, {:collect_messages, name})
  # end

  # used in tests, deletes all elements in the ets tables
  @doc false
  @spec clean :: true
  def clean do
    GenServer.call(__MODULE__, :clean)
  end

  @doc false
  def _account(name) do
    [account] = :ets.lookup(@accounts, name)
    account
  end

  @doc false
  def init(_opts) do
    @accounts = :ets.new(@accounts, [:named_table, keypos: 2])
    @messages = :ets.new(@messages, [:named_table, keypos: 2])
    {:ok, 1}
  end

  @doc false
  def handle_call(message, from, state)

  def handle_call({:create_account, name}, _from, autoincremented_id) do
    :ets.insert(@accounts, account(name: name, id: autoincremented_id))
    {:reply, autoincremented_id, autoincremented_id + 1}
  end

  def handle_call({:save_identity_key, name, identity_key}, _from, state) do
    :ets.update_element(@accounts, name, {position(:identity_key), identity_key})
    {:reply, true, state}
  end

  def handle_call({:save_pre_keys, name, pre_keys}, _from, state) do
    :ets.update_element(@accounts, name, {position(:pre_keys), pre_keys})
    {:reply, true, state}
  end

  def handle_call({:pop_pre_key, name}, _from, state) do
    case :ets.lookup_element(@accounts, name, position(:pre_keys)) do
      [pre_key | rest] ->
        :ets.update_element(@accounts, name, {position(:pre_keys), rest})
        {:reply, pre_key, state}

      [] ->
        {:reply, nil, state}
    end
  end

  def handle_call({:save_signed_pre_key, name, signed_pre_key}, _from, state) do
    :ets.update_element(@accounts, name, {position(:signed_pre_key), signed_pre_key})
    {:reply, true, state}
  end

  def handle_call(:clean, _from, _autoincremented_id) do
    {:reply, :ets.delete_all_objects(@accounts), 1}
  end
end
