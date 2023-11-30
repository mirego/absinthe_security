defmodule AbsintheSecurityTest do
  use ExUnit.Case
  doctest AbsintheSecurity

  test "greets the world" do
    assert AbsintheSecurity.hello() == :world
  end
end
