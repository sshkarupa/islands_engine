defmodule IslandsEngine.Game do
  @moduledoc false

  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

  alias IslandsEngine.{Board, Coordinate, Guesses, Island, Rules}

  @players [:player1, :plyaer2]
  @timeout 60 * 60 * 1000

  def start_link(name) when is_binary(name), do:
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))

  def via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

  def add_player(game, name) when is_binary(name), do:
    GenServer.call(game, {:add_player, name})

  def position_island(game, player, key, row, col) when player in @players, do:
    GenServer.call(game, {:position_island, player, key, row, col})

  def set_islands(game, player) when player in @players, do:
    GenServer.call(game, {:set_islands, player})

  def guess_coordinate(game, player, row, col) when player in @players, do:
    GenServer.call(game, {:guess_coordinate, player, row, col})

  def init(name) do
    send(self(), {:set_state, name})
    {:ok, fresh_state(name)}
  end

  defp fresh_state(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    %{player1: player1, player2: player2, rules: %Rules{}}
  end

  def handle_info({:set_state, name}, _state) do
    state =
      case :ets.lookup(:game_state, name) do
        [] -> fresh_state(name)
        [{_key, state_data}] -> state_data
      end

    :ets.insert(:game_state, {name, state})
    {:noreply, state, @timeout}
  end

  def handle_info(:timeout, state), do:
    {:stop, {:shutdown, :timeout}, state}

  def handle_call({:add_player, name}, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, :add_player)
    do
      state
      |> update_player2_name(name)
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
         %{} = board <- Board.position_island(board, key, island)
    do
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
         true <- Board.all_islands_positioned?(board)
    do
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
         {hit_or_miss, forested_island, win_status, opponent_board} <- Board.guess(opponent_board, coordinate),
         {:ok, rules} <- Rules.check(rules, {:win_check, win_status})
    do
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

  def terminate({:shutdown, :timeout}, state) do
    :ets.delete(:game_state, state.player1.name)
  end

  def terminate(_reason, _state), do: :ok

  defp update_player2_name(state, name), do:
    put_in(state.player2.name, name)

  defp update_board(state, player, board), do:
    Map.update!(state, player, fn player -> %{player | board: board} end)

  defp update_rules(state, rules), do: %{state | rules: rules}

  defp reply(state, reply) do
    :ets.insert(:game_state, {state.player1.name, state})
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
end
