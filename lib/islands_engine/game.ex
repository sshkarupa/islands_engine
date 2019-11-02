defmodule IslandsEngine.Game do
  @moduledoc """
  Public API for a game process that holds a state of the game.
  """

  alias IslandsEngine.{Game.Server, GameRegistry}

  @players [:player1, :player2]

  @doc """
  Spawns a new game process registered under the given `name`.
  """
  def start_link(name) when is_binary(name),
    do: GenServer.start_link(Server, name, name: via_tuple(name))

  def add_player(game, player, name) when is_binary(name) and player in @players,
    do: GenServer.call(game, {:add_player, player, name})

  def position_island(game, player, key, row, col) when player in @players,
    do: GenServer.call(game, {:position_island, player, key, row, col})

  def set_islands(game, player) when player in @players,
    do: GenServer.call(game, {:set_islands, player})

  def guess_coordinate(game, player, row, col) when player in @players,
    do: GenServer.call(game, {:guess_coordinate, player, row, col})

  @doc """
  Returns a tuple used to register and lookup a game server process by name.
  """
  def via_tuple(game_name), do: {:via, Registry, {GameRegistry, game_name}}

  @doc """
  Returns the `pid` of the game process registered under the given `game_name`,
  or `nil` if no process is registered.
  """
  def pid_from_name(name), do: name |> via_tuple() |> GenServer.whereis()
end
