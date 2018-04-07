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
    #Transaction.validate_transaction(transaction)
  end

  def make_payment(key, amount) do
    add_transaction(Transaction.get_new_transaction(key, amount))
  end

  def remove_transactions do
    GenServer.call(__MODULE__, {:remove_transactions,[]})
  end

  def get_transactions do
    GenServer.call(__MODULE__,{:get_transactions,[]})
  end

  def handle_call({choice,tx}, _from, state) do
    new_state = case choice do
      :remove_transactions -> nil
      :add_transaction -> [tx | state]
      :get_transactions -> state
    end
    {:reply, new_state, new_state}
  end

end
