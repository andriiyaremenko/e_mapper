defmodule Test do
  defstruct [:id, :value]
end

defmodule TestViewModel do
  defstruct [:id, :value]
end

defmodule Test_1 do
  defstruct [:id, :value_1]
end

defmodule EMapperTest do
  use ExUnit.Case
  require Logger
  doctest EMapper

  test "can map automatically" do
    assert EMapper.map(%Test{id: 1, value: 3}, TestViewModel) == %TestViewModel{id: 1, value: 3}
  end

  test "can map based on mapping profile" do
    EMapper.add_mapping(Test, Test_1, [value_1: & &1.value])

    assert EMapper.map(%Test{id: 1, value: 3}, Test_1) == %Test_1{id: 1, value_1: 3}
  end

  test "can map to anything" do
    assert EMapper.map(%Test{id: 1, value: 3}, :string, [string: & inspect/1]) == inspect(%Test{id: 1, value: 3})
    EMapper.add_mapping(Test, :number, [number: & &1.value])
    assert EMapper.map(%Test{id: 1, value: 3}, :number) == 3
  end
end
