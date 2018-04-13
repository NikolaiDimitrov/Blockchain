defmodule Blockchain.Transaction.Transaction do
  alias Blockchain.Key.Key
  alias Blockchain.Chain.Worker, as: Chain
  alias Blockchain.Chainstate.Chainstate, as: Chainstate
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

    if(
      :crypto.verify(
        :ecdsa,
        :sha256,
        :erlang.term_to_binary(transaction_list),
        transaction.signature,
        [Key.get_public_key(), :secp256k1]
      ) && Chain.get_acc_balance_by_key(transaction.from_public_key) - transaction.amount >= 0
    ) do
      true
    else
      false
    end
  end

  def complete_transaction(transaction) do
    receiver_acc = %Chainstate{
      public_key: transaction.to_public_key,
      balance: Chain.get_acc_balance_by_key(transaction.to_public_key)
    }

    sender_acc = %Chainstate{
      public_key: transaction.from_public_key,
      balance: Chain.get_acc_balance_by_key(transaction.from_public_key)
    }

    account_list = Chain.get_acc()
    account_list = List.delete(account_list, receiver_acc)
    account_list = List.delete(account_list, sender_acc)
    receiver_acc = %{receiver_acc | balance: receiver_acc.balance + transaction.amount}
    sender_acc = %{sender_acc | balance: sender_acc.balance - transaction.amount}
    account_list = [receiver_acc | account_list]
    account_list = [sender_acc | account_list]
    Chain.update_acc(account_list)
  end
end
