defmodule Chain do
  use GenServer

  def start_link do
    block = %Block{
      previous_hash: nil,
      difficulty: 0,
      nonce: 0,
      chain_state: nil,
      transaction: nil,
      transaction_list: []
    }
    new_state = [block]
    GenServer.start_link(__MODULE__, new_state, [{:name, __MODULE__}])
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:add_block,tx}, _from, state) do
    new_state = [tx | state]
    {:reply, :ok, new_state}
  end

  def handle_call(:get_blocks,_from,state) do
    {:reply,state,state}
  end

  def create_block() do
    [h | _ ] = get_blocks()
    prev_hash = :crypto.hash(:sha256,:erlang.term_to_binary(h))
    list = Pool.get_transactions()
    transaction_hash = calculate_transaction_hash(list)
    %Block{
        previous_hash: prev_hash,
        difficulty: 2,
        nonce: 1,
        chain_state: nil,
        transaction: transaction_hash,
        transaction_list: list
      }

  end

  def add_block(_block) do

  end

  def get_blocks do
    GenServer.call(__MODULE__,:get_blocks )
  end

  def calculate_transaction_hash(transactions) do
    transactions
    |> build_merkle_tree()
    |> :gb_merkle_trees.root_hash()
  end

  def build_merkle_tree(transactions) do
    Enum.reduce(transactions,:gb_merkle_trees.empty(),fn tx,acc->
      tx_bin = :erlang.term_to_binary(tx)
      tx_hash = :crypto.hash(:sha256,tx_bin)
      :gb_merkle_trees.enter(tx_hash,tx_bin,acc)
    end)
  end
end
