defmodule TirexTest do
  use ExUnit.Case
  doctest Tirex

  test "greets the world" do
    assert Tirex.hello() == :world
  end
end
