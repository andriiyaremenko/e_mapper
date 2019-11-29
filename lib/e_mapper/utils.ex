defmodule EMapper.Utils do
  def map(props, el, type, options) do
    values =
      props
      |> Enum.map(
        &case options[&1] do
          :ignore! -> nil
          nil -> el |> Map.get(&1)
          f when is_function(f) -> f.(el)
          prop when is_atom(prop) -> el |> Map.get(prop)
        end
      )

    result = struct(type, Enum.zip(props, values))

    with f when is_function(f) <- options[:after_map!] do
      f.(el, result)
    else
      _ -> result
    end
  end

  def map(props, item, el, type, options) do
    values =
      props
      |> Enum.map(
        &case options[&1] do
          :ignore! -> item |> Map.get(&1)
          nil -> el |> Map.get(&1, Map.get(item, &1))
          f when is_function(f) -> f.(el)
          prop when is_atom(prop) -> el |> Map.get(prop)
        end
      )

    result = struct(type, Enum.zip(props, values))

    with f when is_function(f) <- options[:after_map!] do
      f.(el, result)
    else
      _ -> result
    end
  end

  def reduce(el, acc, type, options) do
    with f when is_function(f) <- options[type] do
      f.(el, acc)
    else
      _ ->
        result =
          options
          |> Enum.filter(fn {key, reducer} -> is_function(reducer) and Map.has_key?(acc, key) end)
          |> Enum.map(fn {key, reducer} -> {key, reducer.(el, Map.get(acc, key))} end)

        fill_item(acc, type, result)
    end
  end

  def fill_item(item, _type, options) when is_map(item) do
    options
    |> Enum.filter(fn {key, value} -> not is_function(value) and Map.has_key?(item, key) end)
    |> Enum.reduce(item, fn {key, value}, acc -> Map.put(acc, key, value) end)
  end

  def fill_item(item, type, options) when is_nil(item) do
    try do
      type |> struct() |> fill_item(type, options)
    rescue
      _ -> nil
    end
  end

  def fill_item(item, _type, _options), do: item

  def get_reduce_atom(type), do: :"reduce(#{type})"
end
