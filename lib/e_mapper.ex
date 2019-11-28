defmodule EMapper do
  @moduledoc """
  Documentation for EMapper.
  """

  alias EMapper.{Server, Utils}

  defdelegate add_mapping(type_1, type_2, opts), to: Server
  defdelegate add_mapping(type_1, type_2, opts, reverse_map), to: Server
  defdelegate add_reduce(type_1, type_2, opts), to: Server

  # map

  @spec map(list(struct), atom) :: list(term)
  def map(elements, type) when is_list(elements) and is_atom(type) do
    elements |> Enum.map(&map(&1, type))
  end

  @spec map(struct, atom) :: term
  def map(el, type) when is_atom(type) do
    opts = el |> Map.get(:__struct__) |> Server.get_mapping(type)
    map(el, type, opts)
  end

  @spec map(list(struct), term, atom) :: list(term)
  def map(elements, item, type) when is_list(elements) and is_atom(type) do
    elements |> Enum.map(&map(&1, item, type))
  end

  @spec map(struct, term, atom) :: term
  def map(el, item, type) when is_atom(type) do
    opts = el |> Map.get(:__struct__) |> Server.get_mapping(type)
    map(el, item, type, opts)
  end

  @spec map(
          list(struct),
          atom,
          list({:after_map | atom, (term, term -> term) | (term -> term) | :ignore! | atom})
        ) :: list(term)
  def map(elements, type, options)
      when is_list(elements) and is_atom(type) and is_list(options) do
    elements |> Enum.map(&map(&1, type, options))
  end

  @spec map(
          struct,
          atom,
          list({:after_map | atom, (term, term -> term) | (term -> term) | :ignore! | atom})
        ) :: term
  def map(el, type, options) when is_atom(type) do
    with f when is_function(f) <- options[type] do
      f.(el)
    else
      _ ->
        [_struct | props] = type |> struct() |> Map.keys()
        Utils.map(props, el, type, options)
    end
  end

  @spec map(
          list(struct),
          term,
          atom,
          list({:after_map | atom, (term, term -> term) | (term -> term) | :ignore! | atom})
        ) :: list(term)
  def map(elements, item, type, options)
      when is_list(elements) and is_atom(type) and is_list(options) do
    elements |> Enum.map(&map(&1, item, type, options))
  end

  @spec map(
          struct,
          term,
          atom,
          list({:after_map | atom, (term, term -> term) | (term -> term) | :ignore! | atom})
        ) :: term
  def map(el, item, type, options) when is_atom(type) do
    with f when is_function(f) <- options[type] do
      f.(el, item)
    else
      _ ->
        [_struct | props] = type |> struct() |> Map.keys()
        Utils.map(props, item, el, type, options)
    end
  end

  # reduce

  @spec reduce(list(struct), atom, atom) :: term
  def reduce(elements, type_1, type_2)
      when is_list(elements) and is_atom(type_1) and is_atom(type_2) do
    opts = type_1 |> Utils.get_reduce_atom() |> Server.get_mapping(type_2)

    reduce(elements, type_2, opts)
  end

  @spec reduce(list(struct), atom, list({atom, (term, term -> term) | term})) :: term
  def reduce(elements, type, options)
      when is_list(elements) and is_atom(type) and is_list(options) do
    item = type |> struct()
    reduce(elements, item, options)
  end

  @spec reduce(list(struct), atom, struct) :: term
  def reduce(elements, type_1, item)
      when is_list(elements) and is_atom(type_1) do
    opts = type_1 |> Utils.get_reduce_atom() |> Server.get_mapping(Map.get(item, :__struct__))

    reduce(elements, item, opts)
  end

  @spec reduce(list(struct), struct, list({atom, (term, term -> term) | term})) :: term
  def reduce(elements, item, options)
      when is_list(elements) and is_list(options) do
    elements
    |> Enum.reduce(
      item |> Utils.fill_struct(options),
      &Utils.reduce(&1, &2, Map.get(item, :__struct__), options)
    )
  end
end
