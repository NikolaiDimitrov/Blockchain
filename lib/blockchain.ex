defmodule Blockchain do
  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    children = [
      Blockchain.Chain.Worker.Supervisor,
      Blockchain.Pool.Worker.Supervisor
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
