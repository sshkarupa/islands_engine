# TODO: Move implementations and callbacks into separate modules Game.Impl and Game.Server
# Keep in this module only public API calls

defmodule IslandsEngine.Game do
  @moduledoc """
  A game process that holds a state of the game.
  """

  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

  alias IslandsEngine.{Board, Coordinate, Guesses, Island, Rules, GameRegistry}

  @players [:player1, :player2]
  @timeout :timer.hours(2)

  # Client (Public) Interface

  @doc """
  Spawns a new game process registered under the given `game_name`.
  """
  def start_link(name) when is_binary(name),
    do: GenServer.start_link(__MODULE__, name, name: via_tuple(name))

  @doc """
  Returns a tuple used to register and lookup a game server process by name.
  """
  def via_tuple(game_name), do: {:via, Registry, {GameRegistry, game_name}}

  @doc """
  Returns the `pid` of the game process registered under the given `game_name`,
  or `nil` if no process is registered.
  """
  def pid_from_name(name), do: name |> via_tuple() |> GenServer.whereis()

  def add_player(game, player, name) when is_binary(name) and player in @players,
    do: GenServer.call(game, {:add_player, player, name})

  def position_island(game, player, key, row, col) when player in @players,
    do: GenServer.call(game, {:position_island, player, key, row, col})

  def set_islands(game, player) when player in @players,
    do: GenServer.call(game, {:set_islands, player})

  def guess_coordinate(game, player, row, col) when player in @players,
    do: GenServer.call(game, {:guess_coordinate, player, row, col})

  # Server Callbacks

  def init(game_name) do
    send(self(), {:set_state, game_name})
    {:ok, fresh_state()}
  end

  defp fresh_state() do
    player1 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    %{player1: player1, player2: player2, rules: %Rules{}}
  end

  def handle_info({:set_state, game_name}, _state) do
    state =
      case :ets.lookup(:game_state, game_name) do
        [] -> fresh_state()
        [{^game_name, state_data}] -> state_data
      end

    :ets.insert(:game_state, {game_name, state})
    {:noreply, state, @timeout}
  end

  def handle_info(:timeout, state), do: {:stop, {:shutdown, :timeout}, state}

  def handle_call({:add_player, player, name}, _from, state) when player in @players do
    with {:ok, rules} <- Rules.check(state.rules, {:add_player, player}) do
      state
      |> update_player_name(player, name)
      |> update_rules(rules)
      |> reply(:ok)
    else
      :error -> reply(state, :error)
    end
  end

  def handle_call({:position_island, player, key, row, col}, _from, state) do
    board = player_board(state, player)

    with {:ok, rules} <- Rules.check(state.rules, {:position_islands, player}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {:ok, island} <- Island.new(key, coordinate),
         %{} = board <- Board.position_island(board, key, island) do
      state
      |> update_board(player, board)
      |> update_rules(rules)
      |> reply(:ok)
    else
      :error ->
        reply(state, :error)

      {:error, :invalid_coordinate} ->
        reply(state, {:error, :invalid_coordinate})

      {:error, :invalid_island_type} ->
        reply(state, {:error, :invalid_island_type})
    end
  end

  def handle_call({:set_islands, player}, _from, state) do
    board = player_board(state, player)

    with {:ok, rules} <- Rules.check(state.rules, {:set_islands, player}),
         true <- Board.all_islands_positioned?(board) do
      state
      |> update_rules(rules)
      |> reply({:ok, board})
    else
      :error ->
        reply(state, :error)

      false ->
        reply(state, {:error, :not_all_islands_positioned})
    end
  end

  def handle_call({:guess_coordinate, player, row, col}, _from, state) do
    opponent = opponent(player)
    opponent_board = player_board(state, opponent)

    with {:ok, rules} <- Rules.check(state.rules, {:guess_coordinate, player}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {hit_or_miss, forested_island, win_status, opponent_board} <-
           Board.guess(opponent_board, coordinate),
         {:ok, rules} <- Rules.check(rules, {:win_check, win_status}) do
      state
      |> update_board(opponent, opponent_board)
      |> update_guesses(player, hit_or_miss, coordinate)
      |> update_rules(rules)
      |> reply({hit_or_miss, forested_island, win_status})
    else
      :error ->
        reply(state, :error)

      {:error, :invalid_coordinate} ->
        reply(state, {:error, :invalid_coordinate})
    end
  end

  defp update_player_name(state, :player1, name), do: put_in(state.player1.name, name)
  defp update_player_name(state, :player2, name), do: put_in(state.player2.name, name)

  defp update_board(state, player, board),
    do: Map.update!(state, player, fn player -> %{player | board: board} end)

  defp update_rules(state, rules), do: %{state | rules: rules}

  defp reply(state, reply) do
    :ets.insert(:game_state, {game_name(), state})
    {:reply, reply, state, @timeout}
  end

  defp player_board(state, player), do: Map.get(state, player).board

  defp opponent(:player1), do: :player2
  defp opponent(:player2), do: :player1

  defp update_guesses(state, player, hit_or_miss, coordinate) do
    update_in(state[player].guesses, fn guesses ->
      Guesses.add(guesses, hit_or_miss, coordinate)
    end)
  end

  def terminate({:shutdown, :timeout}, _state), do: :ets.delete(:game_state, game_name())
  def terminate(_reason, _state), do: :ok

  defp game_name(), do: Registry.keys(GameRegistry, self()) |> List.first()
end
