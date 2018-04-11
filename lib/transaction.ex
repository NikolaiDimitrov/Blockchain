defmodule Transaction do
  defstruct [:from_public_key, :to_public_key, :amount, :signature]

  def get_new_transaction(key, amount) do
    public_key = Key.get_public_key()
    transaction_list = [public_key, key, amount]

    %Transaction{
      from_public_key: public_key,
      to_public_key: key,
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

    :crypto.verify(
      :ecdsa,
      :sha256,
      :erlang.term_to_binary(transaction_list),
      transaction.signature,
      [Key.get_public_key(), :secp256k1]
    )
  end
end
