defmodule Blockchain.Transaction.Transaction do
  alias Blockchain.Key.Key
  alias Blockchain.Miners.Worker, as: Miner
  defstruct [:from_public_key, :to_public_key, :amount, :signature]

  def get_new_transaction(from_key, to_key, amount) do
    transaction_list = [from_key, to_key, amount]

    %Blockchain.Transaction.Transaction{
      from_public_key: from_key,
      to_public_key: to_key,
      amount: amount,
      signature: Key.get_signed_data(transaction_list)
    }
  end

  def validate_transaction(transaction) do
    transaction_list = [
      transaction.from_public_key,
      transaction.to_public_key,
      transaction.amount
    ]

    if(:crypto.verify(
        :ecdsa,
        :sha256,
        :erlang.term_to_binary(transaction_list),
        transaction.signature,
        [Key.get_public_key(), :secp256k1]) && Miner.get_miner_balance_by_key(transaction.from_public_key) - transaction.amount > 0 ) do
      true
    else
      false
    end
  end
end
