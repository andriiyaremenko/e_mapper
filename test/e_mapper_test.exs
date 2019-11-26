defmodule Test do
  defstruct [:id, :value]
end

defmodule TestViewModel do
  defstruct [:id, :value]
end

defmodule Test_1 do
  defstruct [:id, :value_1]
end

defmodule Test_2 do
  defstruct [:id, :value_1, :value_2]
end

defmodule EMapperTest do
  use ExUnit.Case
  require Logger
  doctest EMapper

  setup do
    on_exit(fn ->
      EMapper.Server.delete_mappings()
    end)
  end

  test "can map automatically" do
    assert EMapper.map(%Test{id: 1, value: 3}, TestViewModel) == %TestViewModel{id: 1, value: 3}
  end

  test "can ignore! prop" do
    assert EMapper.map(%Test{id: 1, value: 3}, TestViewModel, [id: :ignore!]) == %TestViewModel{id: nil, value: 3}
  end

  test "can map with callbacks" do
    assert EMapper.map(%Test{id: 1, value: 3}, Test_1, [value_1: & &1.value + 1]) == %Test_1{id: 1, value_1: 4}
  end

  test "can map with properties" do
    assert EMapper.map(%Test{id: 1, value: 3}, Test_1, [value_1: :value]) == %Test_1{id: 1, value_1: 3}
  end

  test "can reverse map" do
    EMapper.add_mapping(Test, Test_1, [value_1: :value], :reverse_map)

    assert EMapper.map(%Test_1{id: 1, value_1: 3}, Test) == %Test{id: 1, value: 3}
  end

  test "can reverse map with ignore!" do
    EMapper.add_mapping(Test, Test_1, [value_1: :value, id: :ignore!], :reverse_map)

    assert EMapper.map(%Test_1{id: 1, value_1: 3}, Test) == %Test{id: nil, value: 3}
  end

  test "can map based on mapping profile" do
    EMapper.add_mapping(Test, Test_1, [value_1: & &1.value])

    assert EMapper.map(%Test{id: 1, value: 3}, Test_1) == %Test_1{id: 1, value_1: 3}
  end

  test "can map based on several mapping profiles" do
    EMapper.add_mapping(Test, Test_2, [value_1: :value])
    EMapper.add_mapping(Test, Test_2, [value_2: & &1.value + 2])

    assert EMapper.map(%Test{id: 1, value: 3}, Test_2) == %Test_2{id: 1, value_1: 3, value_2: 5}
  end

  test "can override mapping" do
    EMapper.add_mapping(Test, Test_2, [value_1: :value, value_2: :value])
    EMapper.add_mapping(Test, Test_2, [value_2: & &1.value + 2])

    assert EMapper.map(%Test{id: 1, value: 3}, Test_2) == %Test_2{id: 1, value_1: 3, value_2: 5}
  end

  test "can map to anything" do
    assert EMapper.map(%Test{id: 1, value: 3}, :string, [string: & inspect/1]) == inspect(%Test{id: 1, value: 3})
    EMapper.add_mapping(Test, :number, [number: & &1.value])
    assert EMapper.map(%Test{id: 1, value: 3}, :number) == 3
  end
end
