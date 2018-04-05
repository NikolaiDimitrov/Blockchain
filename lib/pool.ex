defmodule Pool do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], [{:name, __MODULE__}])
  end

  def init(state) do
    {:ok, state}
  end

  def add_transaction(transaction) do
    GenServer.call(__MODULE__, {:add_transaction, transaction})
  end

  def make_payment(key, amount) do
    add_transaction(Transaction.get_new_transaction(key, amount))
  end

  def handle_call({:add_transaction, tx}, _from, state) do
    new_state = [tx | state]
    {:reply, new_state, new_state}
  end
end
