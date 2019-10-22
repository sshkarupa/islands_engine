defmodule IslandsEngine.CoordinateTest do
  use ExUnit.Case
  alias IslandsEngine.Coordinate
  doctest Coordinate

  describe "Coordinate.new/2" do
    test "valid coordinate" do
      assert Coordinate.new(1, 1) == {:ok, %Coordinate{row: 1, col: 1}}
    end

    test "row is out of range" do
      assert Coordinate.new(11, 1) == {:error, :invalid_coordinate}
    end

    test "col is out of range" do
      assert Coordinate.new(1, 11) == {:error, :invalid_coordinate}
    end

    test "row is negative" do
      assert Coordinate.new(-1, 1) == {:error, :invalid_coordinate}
    end

    test "col is negative" do
      assert Coordinate.new(1, -1) == {:error, :invalid_coordinate}
    end
  end
end
