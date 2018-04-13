defmodule Blockchain.Chain.Worker do
  use GenServer
  use Bitwise

  alias Blockchain.Transaction.Transaction
  alias Blockchain.Block.Block
  alias Blockchain.Key.Key
  alias Blockchain.Pool.Worker, as: Pool
  alias Blockchain.Chainstate.Chainstate

  @difficulty <<255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
                255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255>>
  @acc1_private_key <<46, 184, 100, 190, 87, 62, 77, 146, 237, 139, 78, 171, 207, 115, 254, 230>>
  @acc2_private_key <<24, 151, 126, 33, 62, 159, 21, 72, 114, 188, 199, 232, 126, 170, 56, 164>>
  @acc3_private_key <<83, 177, 121, 203, 209, 7, 115, 228, 136, 223, 95, 146, 125, 55, 97, 246>>
  @acc4_private_key <<244, 176, 126, 253, 97, 165, 70, 237, 72, 216, 247, 193, 251, 222, 161, 50>>
  @acc5_private_key <<54, 212, 21, 139, 172, 196, 97, 242, 184, 147, 28, 245, 83, 143, 182, 84>>

  @coinbase 1
  def start_link(_) do
    block = %Block{
      previous_hash: nil,
      difficulty: 0,
      nonce: 0,
      chain_state_root_hash: nil,
      transaction_root_hash: nil,
      transaction_list: []
    }

    acc1 = %Chainstate{public_key: Key.make_public_key(@acc1_private_key), balance: 100}
    acc2 = %Chainstate{public_key: Key.make_public_key(@acc2_private_key), balance: 100}
    acc3 = %Chainstate{public_key: Key.make_public_key(@acc3_private_key), balance: 100}
    acc4 = %Chainstate{public_key: Key.make_public_key(@acc4_private_key), balance: 100}
    acc5 = %Chainstate{public_key: Key.make_public_key(@acc5_private_key), balance: 100}
    acc_list = [acc1, acc2, acc3, acc4, acc5]
    new_state = %{chain_state: acc_list, blocks: [block]}
    GenServer.start_link(__MODULE__, new_state, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:add_block, tx}, _from, state) do
    new_blocks = [tx | state.blocks]
    {:reply, :ok, %{state | blocks: new_blocks}}
  end

  def handle_call(:get_blocks, _from, state) do
    {:reply, state.blocks, state}
  end

  def handle_call(:get_acc, _from, state) do
    {:reply, state.chain_state, state}
  end

  def handle_call({:update_accounts, acc_list}, _from, state) do
    new_accounts = acc_list
    {:reply, :ok, %{state | chain_state: new_accounts}}
  end

  def handle_call({:add_account, new_acc}, _from, state) do
    new_accounts = [new_acc | state.chain_state]
    {:reply, :ok, %{state | chain_state: new_accounts}}
  end

  def update_acc(acc_list) do
    GenServer.call(__MODULE__, {:update_accounts, acc_list})
  end

  def get_acc() do
    GenServer.call(__MODULE__, :get_acc)
  end

  def add_account(public_key, balance) do
    new_acc = %Chainstate{public_key: public_key, balance: balance}
    GenServer.call(__MODULE__, {:add_account, new_acc})
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

    transaction_list = Enum.reverse(Pool.get_transactions())

    validated_transactions =
      Enum.reduce(transaction_list, [coinbase_transaction], fn tx, valid_txs ->
        if(Transaction.validate_transaction(tx)) do
          Transaction.complete_transaction(tx)
          Pool.remove_transactions(tx)
          [tx | valid_txs]
        else
          valid_txs
        end
      end)

    #  Pool.remove_transactions()
    transaction_hash = calculate_root_hash(validated_transactions)
    chain_state_hash = calculate_root_hash(get_acc())

    block = %Block{
      previous_hash: prev_hash,
      difficulty: 15,
      nonce: 0,
      chain_state_root_hash: chain_state_hash,
      transaction_root_hash: transaction_hash,
      transaction_list: validated_transactions
    }

    <<difficulty::256>> = @difficulty
    nonce = find_nonce(block, difficulty)
    new_block = %{block | nonce: nonce}
    add_block(new_block)
  end

  def add_block(block) do
    GenServer.call(__MODULE__, {:add_block, block})
  end

  def get_blocks do
    GenServer.call(__MODULE__, :get_blocks)
  end

  def calculate_root_hash(transactions) do
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

  def get_acc_balance_by_key(public_key) do
    default = %Chainstate{balance: 0}
    Enum.find(get_acc(), default, fn p -> p.public_key == public_key end).balance
  end

  def find_nonce(block, difficulty) do
    block_bin = :erlang.term_to_binary(block)
    block_hash = :crypto.hash(:sha256, block_bin)
    difficulty = difficulty >>> block.difficulty
    difficulty = <<difficulty::256>>
    find_nonce(block_hash, block, difficulty)
  end

  def find_nonce(hash, block, difficulty) when difficulty < hash do
    block = %{block | nonce: block.nonce + 1}
    block_bin = :erlang.term_to_binary(block)
    block_hash = :crypto.hash(:sha256, block_bin)
    find_nonce(block_hash, block, difficulty)
  end

  def find_nonce(_hash, block, _difficulty) do
    block.nonce
  end
end
