defmodule IslandsEngine.GameSupervisor do
  @moduledoc """
  A supervisor that starts `Game` processes dynamically.
  """

  use DynamicSupervisor
  alias IslandsEngine.Game

  def start_link(_opts), do: DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)

  @doc """
  Starts a `Game` process and supervises it.
  """
  def start_game(name) do
    spec = %{id: Game, start: {Game, :start_link, [name]}, restart: :transient}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @doc """
  Terminates the `Game` process normally. It won't be restarted.
  """
  def stop_game(name) do
    :ets.delete(:game_state, name)
    DynamicSupervisor.terminate_child(__MODULE__, Game.pid_from_name(name))
  end
end
