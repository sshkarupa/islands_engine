defmodule IslandsEngine.IslandTest do
  use ExUnit.Case
  alias IslandsEngine.{Coordinate, Island}

  setup_all do
    {:ok, coordinate} = Coordinate.new(1, 1)
    {:ok, coordinate: coordinate}
  end

  describe "Island.new/2" do
    test "valid island type (:square)", %{coordinate: coordinate} = _context do
      assert %IslandsEngine.Island{} = Island.new(:square, coordinate)
    end

    test "valid island type (:atoll)", %{coordinate: coordinate} = _context do
      assert %IslandsEngine.Island{} = Island.new(:atoll, coordinate)
    end

    test "valid island type (:dot)", %{coordinate: coordinate} = _context do
      assert %IslandsEngine.Island{} = Island.new(:dot, coordinate)
    end

    test "valid island type (:l_shape)", %{coordinate: coordinate} = _context do
      assert %IslandsEngine.Island{} = Island.new(:l_shape, coordinate)
    end

    test "valid island type (:s_shape)", %{coordinate: coordinate} = _context do
      assert %IslandsEngine.Island{} = Island.new(:s_shape, coordinate)
    end

    test "invalid island type", %{coordinate: coordinate} = _context do
      {:ok, coordinate} = Coordinate.new(1, 1)
      assert Island.new(:wrong, coordinate) == {:error, :invalid_island_type}
    end

    test "invalid start coordinate" do
      {:ok, coordinate} = Coordinate.new(10, 10)
      assert Island.new(:square, coordinate) == {:error, :invalid_coordinate}
    end
  end
end
