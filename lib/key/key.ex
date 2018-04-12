defmodule Blockchain.Key.Key do
  @private_key <<172, 106, 222, 228, 33, 177, 141, 9, 206, 113, 147, 222, 16, 24, 67, 105>>

  def get_public_key() do
    {public_key, _} = :crypto.generate_key(:ecdh, :secp256k1, @private_key)
    public_key
  end

  def get_signed_data(transaction_list) do
    :crypto.sign(:ecdsa, :sha256, :erlang.term_to_binary(transaction_list), [
      @private_key,
      :secp256k1
    ])
  end
end
