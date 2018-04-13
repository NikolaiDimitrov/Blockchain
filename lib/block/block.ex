defmodule Blockchain.Block.Block do
  defstruct [
    :previous_hash,
    :difficulty,
    :nonce,
    :chain_state_root_hash,
    :transaction_root_hash,
    :transaction_list
  ]
end
