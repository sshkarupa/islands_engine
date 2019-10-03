defmodule IslandsEngine.GuessesTest do
  use ExUnit.Case
  alias IslandsEngine.Guesses
  doctest Guesses

  describe "Guesses.new/0" do
    test "create a %Guesses{} struct" do
      assert %Guesses{} = Guesses.new()
    end
  end
end