defmodule EMapper do
  @moduledoc """
  Documentation for EMapper.
  """

  alias EMapper.Server
  require Logger

  def add_mapping(type_1, type_2, opts) do
    Server.add_mapping(type_1, type_2, opts)
  end

  def map(elements, type) when is_list(elements) do
    elements |> Enum.map(&map(&1, type))
  end

  def map(el, type) do
    opts = el |> Map.get(:__struct__) |> Server.get_mapping(type)
    map(el, type, opts)
  end

  def map(elements, type, options) when is_list(elements) do
    elements |> Enum.map(&map(&1, type, options))
  end

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
        &with f when is_function(f) <- options[&1] do
          f.(el)
        else
          _ -> el |> Map.get(&1)
        end
      )

    struct(type, Enum.zip(props, values))
  end
end
