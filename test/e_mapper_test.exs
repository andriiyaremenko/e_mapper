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

  # map

  test "can map automatically" do
    assert EMapper.map(%Test{id: 1, value: 3}, TestViewModel) == %TestViewModel{id: 1, value: 3}
  end

  test "can ignore! prop" do
    assert EMapper.map(%Test{id: 1, value: 3}, TestViewModel, id: :ignore!) == %TestViewModel{
             id: nil,
             value: 3
           }
  end

  test "can map with callbacks" do
    assert EMapper.map(%Test{id: 1, value: 3}, Test_1, value_1: &(&1.value + 1)) == %Test_1{
             id: 1,
             value_1: 4
           }
  end

  test "can map with properties" do
    assert EMapper.map(%Test{id: 1, value: 3}, Test_1, value_1: :value) == %Test_1{
             id: 1,
             value_1: 3
           }
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
    EMapper.add_mapping(Test, Test_1, value_1: & &1.value)

    assert EMapper.map(%Test{id: 1, value: 3}, Test_1) == %Test_1{id: 1, value_1: 3}
  end

  test "can map based on several mapping profiles" do
    EMapper.add_mapping(Test, Test_2, value_1: :value)
    EMapper.add_mapping(Test, Test_2, value_2: &(&1.value + 2))

    assert EMapper.map(%Test{id: 1, value: 3}, Test_2) == %Test_2{id: 1, value_1: 3, value_2: 5}
  end

  test "can override mapping" do
    EMapper.add_mapping(Test, Test_2, value_1: :value, value_2: :value)
    EMapper.add_mapping(Test, Test_2, value_2: &(&1.value + 2))

    assert EMapper.map(%Test{id: 1, value: 3}, Test_2) == %Test_2{id: 1, value_1: 3, value_2: 5}
  end

  test "can map to anything" do
    assert EMapper.map(%Test{id: 1, value: 3}, :string, string: &inspect/1) ==
             inspect(%Test{id: 1, value: 3})

    EMapper.add_mapping(Test, :number, number: & &1.value)
    assert EMapper.map(%Test{id: 1, value: 3}, :number) == 3
  end

  test "can map to existing item" do
    assert EMapper.map(%Test{id: 1, value: 3}, %Test_2{value_2: 5}, Test_2, value_1: :value) ==
             %Test_2{id: 1, value_1: 3, value_2: 5}
  end

  test "can map to existing item based on mapping profile" do
    EMapper.add_mapping(Test, Test_2, value_1: :value)

    assert EMapper.map(%Test{id: 1, value: 3}, %Test_2{value_2: 5}, Test_2) == %Test_2{
             id: 1,
             value_1: 3,
             value_2: 5
           }
  end

  test "can map list" do
    EMapper.add_mapping(Test, Test_2, value_1: :value)

    assert get_list() |> EMapper.map(Test_2) == [
             %Test_2{id: 1, value_1: 2, value_2: nil},
             %Test_2{id: 2, value_1: 4, value_2: nil},
             %Test_2{id: 3, value_1: 5, value_2: nil}
           ]

    assert get_list() |> EMapper.map(%Test_2{value_2: 5}, Test_2) == [
             %Test_2{id: 1, value_1: 2, value_2: 5},
             %Test_2{id: 2, value_1: 4, value_2: 5},
             %Test_2{id: 3, value_1: 5, value_2: 5}
           ]
  end

  test "can use after_map" do
    EMapper.add_mapping(Test, Test_2, value_1: :value, after_map!: &%{&2 | value_2: &2.value_2 + &1.value})

    assert EMapper.map(%Test{id: 1, value: 3}, %Test_2{value_2: 5}, Test_2) == %Test_2{
             id: 1,
             value_1: 3,
             value_2: 8
           }
  end

  # reduce

  test "can reduce" do
    assert get_list()
           |> EMapper.reduce(Test_1, id: 1, value_1: 0, value_1: &(&1.value + &2)) == %Test_1{
             id: 1,
             value_1: 11
           }
  end

  test "can reduce based on mapping profile" do
    EMapper.add_reduce(Test, Test_1, id: 1, value_1: 0, value_1: &(&1.value + &2))

    assert get_list() |> EMapper.reduce(Test_1) == %Test_1{
             id: 1,
             value_1: 11
           }
  end

  test "can reduce to existing item" do
    assert get_list()
           |> EMapper.reduce(%Test_2{value_1: 0, value_2: 7}, Test_2,
             id: 1,
             value_1: &(&1.value + &2)
           ) ==
             %Test_2{
               id: 1,
               value_1: 11,
               value_2: 7
             }
  end

  test "can reduce to existing item based on mapping profile" do
    EMapper.add_reduce(Test, Test_2, value_1: &(&1.value + &2))

    assert get_list()
           |> EMapper.reduce(%Test_2{id: 1, value_1: 0, value_2: 7}, Test_2) ==
             %Test_2{
               id: 1,
               value_1: 11,
               value_2: 7
             }
  end

  test "can reduce to any type" do
    assert get_list()
           |> EMapper.reduce(:string,
             string:
               &if &2 == nil do
                 "#{&1.value}, "
               else
                 "#{&2}#{&1.value}, "
               end
           ) == "2, 4, 5, "

    EMapper.add_reduce(Test, :number,
      number:
        &if &2 != nil do
          &2 + &1.value
        else
          &1.value
        end
    )

    assert get_list() |> EMapper.reduce(5, :number) == 5 + 2 + 4 + 5
  end

  defp get_list,
    do: [%Test{id: 1, value: 2}, %Test{id: 2, value: 4}, %Test{id: 3, value: 5}]
end
