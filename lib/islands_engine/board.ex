defmodule IslandsEngine.Board do
  alias IslandsEngine.{Island, Coordinate}

  def new(), do: %{}

  @doc """
  Given a board and an island, puts the island on the board if one is not overlaps
  with the other islands. Retuns `{:error, :overlapping_island}` tuple in another case.
  """
  def position_island(board, key, %Island{} = island) do
    case overlaps_existing_islands?(board, key, island) do
      true  -> {:error, :overlapping_island}
      false -> Map.put(board, key, island)
    end
  end

  defp overlaps_existing_islands?(board, new_key, new_island) do
    Enum.any?(board, fn {key, island} ->
      new_key != key and Island.overlap?(island, new_island)
    end)
  end

  @doc """
  Given a board, return `true` if all type of islands positioned on the board
  """
  def all_islands_positioned?(board), do: Enum.all?(Island.types, &(Map.has_key?(board, &1)))

  @doc """
  Checks all the islands in the board for a match and then formulates the full response
  """
  def guess(board, %Coordinate{} = coordinate) do
    board
    |> check_all_islands(coordinate)
    |> guess_response(board)
  end

  defp check_all_islands(board, coordinate) do
    Enum.find_value(board, :miss, fn {key, island} ->
      case Island.guess(island, coordinate) do
        {:hit, island} -> {key, island}
        :miss          -> false
      end
    end)
  end

  defp guess_response({key, island}, board) do
    board = %{board | key => island}
    {:hit, forest_check(board, key), win_check(board), board}
  end
  defp guess_response(:miss, board), do: {:miss, :none, :no_win, board}

  defp forest_check(board, key) do
    case forested?(board, key) do
      true  -> key
      false -> :none
    end
  end

  defp forested?(board, key) do
    board
    |> Map.fetch!(key)
    |> Island.forested?()
  end

  defp win_check(board) do
    case all_forested?(board) do
       true  -> :win
       false -> :no_win
    end
  end

  defp all_forested?(board) do
    Enum.all?(board, fn {_key, island} -> Island.forested?(island) end)
  end
end
