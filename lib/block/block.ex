defmodule Blockchain.Block.Block do
  defstruct [:previous_hash, :difficulty, :nonce, :chain_state, :transaction, :transaction_list]
end
