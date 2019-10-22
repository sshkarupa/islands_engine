defmodule IslandsEngine.Coordinate do
  @moduledoc false

  alias __MODULE__

  @enforce_keys [:row, :col]
  defstruct [:row, :col]
  @board_range 1..10

  @doc """
  Creates a Coordinate struct from given row and column numbers
  """
  def new(row, col) when row in @board_range and col in @board_range do
    {:ok, %Coordinate{row: row, col: col}}
  end

  def new(_, _), do: {:error, :invalid_coordinate}
end
