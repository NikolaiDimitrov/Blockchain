defmodule Pool do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], [{:name, __MODULE__}])
  end

  def init(state) do
    {:ok, state}
  end

  def add_transaction(transaction) do
    if(Transaction.validate_transaction(transaction)) do
      GenServer.call(__MODULE__, {:add_transaction, transaction})
      IO.puts("Transaction added")
    else
      IO.puts("Transaction not added")
    end
  end

  def make_payment(key, amount) do
    add_transaction(Transaction.get_new_transaction(key, amount))
  end

  def remove_transactions do
    GenServer.call(__MODULE__, :remove_transactions)
  end

  def get_transactions do
    GenServer.call(__MODULE__, :get_transactions)
  end

  def handle_call({:add_transaction, tx}, _from, state) do
    new_state = [tx | state]
    {:reply, :ok, new_state}
  end

  def handle_call(:remove_transactions, _from, _state) do
    {:reply, :ok, []}
  end

  def handle_call(:get_transactions, _from, state) do
    {:reply, state, state}
  end
end
