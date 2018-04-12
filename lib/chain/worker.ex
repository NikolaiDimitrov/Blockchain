defmodule Blockchain.Chain.Worker do
  use GenServer

  alias Blockchain.Transaction.Transaction
  alias Blockchain.Block.Block
  alias Blockchain.Key.Key
  alias Blockchain.Pool.Worker, as: Pool

  @difficulty <<0, 63, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
                255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255>>
  @coinbase 1
  def start_link(_) do
    block = %Block{
      previous_hash: nil,
      difficulty: 0,
      nonce: 0,
      chain_state: nil,
      transaction: nil,
      transaction_list: []
    }

    new_state = [block]
    GenServer.start_link(__MODULE__, new_state, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:add_block, tx}, _from, state) do
    new_state = [tx | state]
    {:reply, :ok, new_state}
  end

  def handle_call(:get_blocks, _from, state) do
    {:reply, state, state}
  end

  def create_block() do
    [h | _] = get_blocks()
    prev_hash = :crypto.hash(:sha256, :erlang.term_to_binary(h))

    coinbase_transaction = %Transaction{
      from_public_key: nil,
      to_public_key: Key.get_public_key(),
      signature: nil,
      amount: @coinbase
    }

    transaction_list = Pool.get_transactions()

    validated_transactions =
      Enum.reduce(transaction_list, [coinbase_transaction], fn tx, valid_txs ->
        if(Transaction.validate_transaction(tx)) do
          [tx | valid_txs]
        else
          valid_txs
        end
      end)

    Pool.remove_transactions()
    #  transaction_hash = calculate_transaction_hash(list)
    block = %Block{
      previous_hash: prev_hash,
      difficulty: 10,
      nonce: 0,
      chain_state: nil,
      transaction: nil,
      transaction_list: validated_transactions
    }

    nonce = find_nonce(block)
    new_block = %{block | nonce: nonce}
    add_block(new_block)
  end

  def add_block(block) do
    GenServer.call(__MODULE__, {:add_block, block})
  end

  def get_blocks do
    GenServer.call(__MODULE__, :get_blocks)
  end

  def calculate_transaction_hash(transactions) do
    transactions
    |> build_merkle_tree()
    |> :gb_merkle_trees.root_hash()
  end

  def build_merkle_tree(transactions) do
    Enum.reduce(transactions, :gb_merkle_trees.empty(), fn tx, acc ->
      tx_bin = :erlang.term_to_binary(tx)
      tx_hash = :crypto.hash(:sha256, tx_bin)
      :gb_merkle_trees.enter(tx_hash, tx_bin, acc)
    end)
  end

  def find_nonce(block) do
    block_bin = :erlang.term_to_binary(block)
    block_hash = :crypto.hash(:sha256, block_bin)
    find_nonce(block_hash, block)
  end

  def find_nonce(hash, block) when @difficulty < hash do
    block = %{block | nonce: block.nonce + 1}
    block_bin = :erlang.term_to_binary(block)
    block_hash = :crypto.hash(:sha256, block_bin)
    find_nonce(block_hash, block)
  end

  def find_nonce(_hash, block) do
    block.nonce
  end
end
