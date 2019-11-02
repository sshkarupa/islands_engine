defmodule IslandsEngine do
  use Application

  def start(_type, _args) do
    :ets.new(:game_state, [:public, :named_table])

    children = [
      {Registry, keys: :unique, name: IslandsEngine.GameRegistry},
      IslandsEngine.GameSupervisor
    ]

    opts = [strategy: :one_for_one, name: IslandsEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
