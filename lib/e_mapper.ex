defmodule EMapper do
  @moduledoc """
  Documentation for EMapper.
  """

  alias EMapper.Server

  defdelegate add_mapping(type_1, type_2, opts), to: Server
  defdelegate add_mapping(type_1, type_2, opts, reverse_map), to: Server

  @spec map(list(struct), atom) :: list(term)
  def map(elements, type) when is_list(elements) do
    elements |> Enum.map(&map(&1, type))
  end

  @spec map(struct, atom) :: term
  def map(el, type) do
    opts = el |> Map.get(:__struct__) |> Server.get_mapping(type)
    map(el, type, opts)
  end

  @spec map(list(struct), atom, list({atom, term})) :: list(term)
  def map(elements, type, options) when is_list(elements) do
    elements |> Enum.map(&map(&1, type, options))
  end

  @spec map(struct, atom, list({atom, (term -> term) | :ignore! | atom})) :: term
  def map(el, type, options) do
    with f when is_function(f) <- options[type] do
      f.(el)
    else
      _ ->
        [_struct | props] = type |> struct() |> Map.keys()
        map(props, el, type, options)
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
end
