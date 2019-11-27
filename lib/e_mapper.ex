defmodule EMapper do
  @moduledoc """
  Documentation for EMapper.
  """

  alias EMapper.Server

  defdelegate add_mapping(type_1, type_2, opts), to: Server
  defdelegate add_mapping(type_1, type_2, opts, reverse_map), to: Server

  @spec add_reduce(atom, atom, list({atom, (term, term -> term) | term})) :: :ok | {:error, term}
  def add_reduce(type_1, type_2, options),
    do: type_1 |> get_reduce_atom() |> Server.add_mapping(type_2, options)

  @spec map(list(struct), atom) :: list(term)
  def map(elements, type) when is_list(elements) and is_atom(type) do
    elements |> Enum.map(&map(&1, type))
  end

  @spec map(struct, atom) :: term
  def map(el, type) when is_atom(type) do
    opts = el |> Map.get(:__struct__) |> Server.get_mapping(type)
    map(el, type, opts)
  end

  @spec map(list(struct), atom, list({atom, (term -> term) | :ignore! | atom})) :: list(term)
  def map(elements, type, options) when is_list(elements) and is_atom(type) do
    elements |> Enum.map(&map(&1, type, options))
  end

  @spec map(struct, atom, list({atom, (term -> term) | :ignore! | atom})) :: term
  def map(el, type, options) when is_atom(type) do
    with f when is_function(f) <- options[type] do
      f.(el)
    else
      _ ->
        [_struct | props] = type |> struct() |> Map.keys()
        map(props, el, type, options)
    end
  end

  @spec reduce(list(struct), atom, atom) :: term
  def reduce(elements, type_1, type_2) when is_atom(type_2) do
    opts = type_1 |> get_reduce_atom() |> Server.get_mapping(type_2)

    reduce(elements, type_2, opts)
  end

  @spec reduce(list(struct), atom, list({atom, (term, term -> term) | term})) :: term
  def reduce(elements, type, options) when is_list(options) and is_atom(type) do
    case elements do
      nil ->
        struct(type)

      elements when is_list(elements) ->
        elements
        |> Enum.reduce(type |> struct() |> fill_struct(options), &reduce(&1, &2, type, options))

      _ ->
        throw(
          {:error,
           %ArgumentError{
             message:
               "Wrong argument: \nreduce(#{inspect(elements)}, #{inspect(type)}, #{
                 inspect(options)
               })\nShould be: reduce(list(struct), ...)"
           }}
        )
    end
  end

  defp map(props, el, type, options) do
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

    struct(type, Enum.zip(props, values))
  end

  defp reduce(el, acc, type, options) do
    with f when is_function(f) <- options[type] do
      f.(el, acc)
    else
      _ ->
        result =
          options
          |> Enum.filter(fn {key, reducer} -> is_function(reducer) and Map.has_key?(acc, key) end)
          |> Enum.map(fn {key, reducer} -> {key, reducer.(el, Map.get(acc, key))} end)

        fill_struct(acc, result)
    end
  end

  defp fill_struct(struct, options) do
    options
    |> Enum.filter(fn {key, value} -> not is_function(value) and Map.has_key?(struct, key) end)
    |> Enum.reduce(struct, fn {key, value}, acc -> Map.put(acc, key, value) end)
  end

  defp get_reduce_atom(type), do: :"reduce(#{type})"
end
