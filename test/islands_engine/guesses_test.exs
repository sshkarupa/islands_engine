defmodule IslandsEngine.GuessesTest do
  use ExUnit.Case
  alias IslandsEngine.{Guesses, Coordinate}
  doctest Guesses

  setup_all do
    {:ok, coordinate} = Coordinate.new(1, 1)
    {:ok, coordinate: coordinate}
  end

  describe "Guesses.new/0" do
    test "create a %Guesses{} struct" do
      assert %Guesses{} = Guesses.new()
    end
  end

  describe "Guesses.add/3" do
    test "adds a coordinate to :hit coordinates", %{coordinate: coordinate} = _context do
      guesses = Guesses.new()

      assert Guesses.add(guesses, :hit, coordinate) == %Guesses{
               hits: MapSet.new([coordinate]),
               misses: MapSet.new()
             }
    end

    test "adds a coordinate to :miss coordinates", %{coordinate: coordinate} = _context do
      guesses = Guesses.new()

      assert Guesses.add(guesses, :miss, coordinate) == %Guesses{
               hits: MapSet.new(),
               misses: MapSet.new([coordinate])
             }
    end
  end
end
