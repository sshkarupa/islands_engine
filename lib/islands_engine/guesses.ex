defmodule IslandsEngine.Guesses do
  alias IslandsEngine.{Guesses, Coordinate}

  @enforce_keys [:hits, :misses]
  defstruct [:hits, :misses]

  @doc """
  Creates an empty Guesses struct
  """
  def new() do
    %Guesses{hits: MapSet.new(), misses: MapSet.new()}
  end

  @doc """
  Updates hits coordinates
  """
  def add(%Guesses{} = guesses, :hit, %Coordinate{} = coordinate) do
    update_in(guesses.hits, &MapSet.put(&1, coordinate))
  end

  @doc """
  Updates misses coordinates
  """
  def add(%Guesses{} = guesses, :miss, %Coordinate{} = coordinate) do
    update_in(guesses.misses, &MapSet.put(&1, coordinate))
  end
end