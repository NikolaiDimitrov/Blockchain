defmodule Blockchain.Miners.Worker do
  use GenServer

  alias Blockchain.Chainstate.Chainstate

  def start_link(_) do
    miner1 = %Chainstate{public_key: 10, balance: 100}
    miner2 = %Chainstate{public_key: 11, balance: 100}
    miner3 = %Chainstate{public_key: 12, balance: 100}
    miner4 = %Chainstate{public_key: 13, balance: 100}
    miner5 = %Chainstate{public_key: 14, balance: 100}
    miners_list = [miner1, miner2, miner3, miner4, miner5]
    GenServer.start_link(__MODULE__, miners_list, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:get_miners, _from, state) do
    {:reply, state, state}
  end

  def get_miners() do
    GenServer.call(__MODULE__, :get_miners)
  end

  def get_miner_balance_by_key(public_key) do
    Enum.find(get_miners(), fn p -> p.public_key == public_key end).balance
  end
end
