defmodule IslandsEngine.GameSupervisor do
  @moduledoc false

  use DynamicSupervisor
  alias IslandsEngine.Game

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_game(name), do: DynamicSupervisor.start_child(__MODULE__, [name])

  def stop_game(name), do: DynamicSupervisor.terminate_child(__MODULE__, pid_from_name(name))

  def init(:ok) do
    DynamicSupervisor.init([Game], strategy: :one_for_one)
  end

  defp pid_from_name(name) do
    name
    |> Game.via_tuple()
    |> GenServer.whereis()
  end
end