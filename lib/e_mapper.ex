defmodule EMapper do
  @moduledoc """
  # Documentation for EMapper.
  It is made for making transforming structs into other objects simple
  """

  alias EMapper.{Server, Utils}

  @doc """
  Adds mapping from `type_1` to `type_2`

  ## Parameters:

    - `type_1` - name of the struct to map from

    - `type_2` - name of the struct or any other type to map to

    - `opts` - key-value list of mapping options:
      * Keys can be:
        - `:after_map!`
        - `type_2`
        - atom representing one of `type_2` property  if it is a struct
      * Values can be:
        - `:ignore!` to ignore property while mapping
        - `fn src, dest -> dest end` for `:after_map!` or `type_2` keys
        - atom representing one of `type_1` properties
        - `fn src -> value end` to calculate value for property

  ## Examples:

  ```elixir
    iex> EMapper.add_mapping(User, Employee,
    ...> short_name: :first_name,
    ...> full_name: & &1.first_name <> " " <> &1.last_name)
    :ok

  ```
  """
  defdelegate add_mapping(type_1, type_2, opts), to: Server

  @doc """
  Adds mapping from `type_1` to `type_2` and reverse mapping from `type_2` to `type_1`

  ## Parameters:

    - `type_1` - name of the struct to map from

    - `type_2` - name of the struct or any other type to map to

    - `opts` - key-value list of mapping options:
      * Keys can be:
        - `:after_map!`
        - `type_2`
        - atom representing one of `type_2` property  if it is a struct
      * Values can be:
        - `:ignore!` to ignore property while mapping
        - `fn src, dest -> dest end` for `:after_map!` or `type_2` keys
        - atom representing one of `type_1` properties
        - `fn src -> value end` to calculate value for property

    - `:reverse_map` - atom indicating that reversed map should be added. It will reverse key-value pairs for all properties where there is a straight property to property map: `value: :short_name` -> `short_name: :value`

  ## Examples:

  ```elixir
    iex> EMapper.add_mapping(User, Employee,
    ...> [short_name: :first_name,
    ...> full_name: & &1.first_name <> " " <> &1.last_name],
    ...> :reverse_map)
    :ok

  ```
  """
  defdelegate add_mapping(type_1, type_2, opts, reverse_map), to: Server

  @doc """
  Adds mapping from list of `type_1` instances to single instance `type_2`

  ## Parameters:

    - `type_1` - name of the struct to map from

    - `type_2` - name of the struct or any other type to map to

    - `opts` - key-value list of mapping options:
      * Keys can be:
        - `type_2`
        - any key in `type_2` if it is a struct
      * Values can be:
        - `fn src, value -> value end` - accumulator function
        - `fn src, dest -> dest end` for `type_2` key
        - value - value (will be assigned before first element of reduce list is processed)

  ## Examples:

  ```elixir
    iex> EMapper.add_reduce(Transaction, Balance, amount: & &2 + &1.amount)
    :ok

  ```
  """
  defdelegate add_reduce(type_1, type_2, opts), to: Server

  # map

  @doc """
  Maps `elements` to list of `type` instances based on previously defined scheme in `add_mapping(...)`

  ## Parameters:

    - `elements` - list of elements to map from

    - `type` - type name to map to

  ## Examples:

  ```elixir
    iex> EMapper.add_mapping(User, Employee,
    ...> short_name: :first_name,
    ...> full_name: & &1.first_name <> " " <> &1.last_name)
    iex> [%User{id: 1, first_name: "John", last_name: "Savage"},
    ...> %User{id: 2, first_name: "Pete" last_name: "Funny"}]
    ...> |> EMapper.map(Employee)
    [%Employee{id: 1, short_name: "John", full_name: "Jonh Savage"},
      %Employee{id: 2, short_name: "Pete" full_name: "Pete Funny"}]

  ```
  """
  @spec map(list(struct), atom) :: list(term)
  def map(elements, type) when is_list(elements) and is_atom(type) do
    elements |> Enum.map(&map(&1, type))
  end

  @doc """
  Maps `el` to `type` instance based on previously defined scheme in `add_mapping(...)`

  ## Parameters:

    - `el` - element to map from

    - `type` - type name to map to

  ## Examples:

  ```elixir
    iex> EMapper.add_mapping(User, Employee,
    ...> short_name: :first_name,
    ...> full_name: & &1.first_name <> " " <> &1.last_name)
    iex> %User{id: 1, first_name: "John", last_name: "Savage"} |> EMapper.map(Employee)
    %Employee{id: 1, short_name: "John", full_name: "John Savage"}

    ```
  """
  @spec map(struct, atom) :: term
  def map(el, type) when is_atom(type) do
    opts = el |> Map.get(:__struct__) |> Server.get_mapping(type)
    map(el, type, opts)
  end

  @doc """
  Maps `elements` to list of `type` instances based on previously defined scheme in `add_mapping(...)` using `item` as seed for each element

  ## Parameters:

    - `elements` - list of elements to map from

    - `item` - instance of type to map to

    - `type` - type name to map to

  ## Examples:

  ```elixir
    iex> EMapper.add_mapping(User, Employee,
    ...> short_name: :first_name,
    ...> full_name: & &1.first_name <> " " <> &1.last_name)
    iex> [%User{id: 1, first_name: "John", last_name: "Savage"},
    ...> %User{id: 2, first_name: "Pete" last_name: "Funny"}]
    ...> |> EMapper.map(%Employee{id: 1}, Employee)
    [%Employee{id: 1, short_name: "John", full_name: "John Savage"},
      %Employee{id: 2, short_name: "Pete" full_name: "Pete Funny"}]

  ```
  """
  @spec map(list(struct), term, atom) :: list(term)
  def map(elements, item, type) when is_list(elements) and is_atom(type) do
    elements |> Enum.map(&map(&1, item, type))
  end

  @doc """
  Maps `el` to `item` based on previously defined scheme for `type` in `add_mapping(...)`

  ## Parameters:

    - `el` - element to map from

    - `item` - instance of type to map to

    - `type` - type name to map to

  ## Examples:

  ```elixir
    iex> EMapper.add_mapping(User, Employee,
    ...> short_name: :first_name,
    ...> full_name: & &1.first_name <> " " <> &1.last_name)
    iex> %User{id: 1, first_name: "John", last_name: "Savage"}
    ...> |> EMapper.map(%Employee{id: 1}, Employee)
    %Employee{id: 1, short_name: "John", full_name: "John Savage"}

  ```
  """
  @spec map(struct, term, atom) :: term
  def map(el, item, type) when is_atom(type) do
    opts = el |> Map.get(:__struct__) |> Server.get_mapping(type)
    map(el, item, type, opts)
  end

  @doc """
  Maps `elements` to list of `type` instances based on scheme defined in `options`

  ## Parameters:

    - `elements` - list of elements to map from

    - `type` - type name to map to

    - `options` - key-value list of mapping options:
      * Keys can be:
        - `:after_map!`
        - `type_2`
        - atom representing one of `type_2` property  if it is a struct
      * Values can be:
        - `:ignore!` to ignore property while mapping
        - `fn src, dest -> dest end` for `:after_map!` or `type_2` keys
        - atom representing one of `type_1` properties
        - `fn src -> value end` to calculate value for property

  ## Examples:

  ```elixir
    iex> [%User{id: 1, first_name: "John", last_name: "Savage"},
    ...> %User{id: 2, first_name: "Pete", last_name: "Funny"}]
    ...> |> EMapper.map(Employee,
    ...> short_name: :first_name,
    ...> full_name: & &1.first_name <> " " <> &1.last_name)
    [%Employee{id: 1, short_name: "John", full_name: "John Savage"},
      %Employee{id: 2, short_name: "Pete" full_name: "Pete Funny"}]

  ```
  """
  @spec map(
          list(struct),
          atom,
          list({:after_map! | atom, (term, term -> term) | (term -> term) | :ignore! | atom})
        ) :: list(term)
  def map(elements, type, options)
      when is_list(elements) and is_atom(type) and is_list(options) do
    elements |> Enum.map(&map(&1, type, options))
  end

  @doc """
  Maps `el` to `type` instance based on scheme defined in `options`

  ## Parameters:

    - `el` - element to map from

    - `type` - type name to map to

    - `options` - key-value list of mapping options:
      * Keys can be:
        - `:after_map!`
        - `type_2`
        - atom representing one of `type_2` property  if it is a struct
      * Values can be:
        - `:ignore!` to ignore property while mapping
        - `fn src, dest -> dest end` for `:after_map!` or `type_2` keys
        - atom representing one of `type_1` properties
        - `fn src -> value end` to calculate value for property

  ## Examples:

  ```elixir
    iex> %User{id: 1, first_name: "John", last_name: "Savage"}
    ...> |> EMapper.map(Employee,
    ...> short_name: :first_name,
    ...> full_name: & &1.first_name <> " " <> &1.last_name)
    %Employee{id: 1, short_name: "John", full_name: "John Savage"}

  ```
  """
  @spec map(
          struct,
          atom,
          list({:after_map! | atom, (term, term -> term) | (term -> term) | :ignore! | atom})
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

  @doc """
  Maps `elements` to list of `type` instances based on scheme defined in `options` using `item` as seed

  ## Parameters:

    - `elements` - list of elements to map from

    - `item` - instance of type to map to

    - `type` - type name to map to

    - `options` - key-value list of mapping options:
      * Keys can be:
        - `:after_map!`
        - `type_2`
        - atom representing one of `type_2` property  if it is a struct
      * Values can be:
        - `:ignore!` to ignore property while mapping
        - `fn src, dest -> dest end` for `:after_map!` or `type_2` keys
        - atom representing one of `type_1` properties
        - `fn src -> value end` to calculate value for property

  ## Examples:

  ```elixir
    iex> [%User{id: 1, first_name: "John", last_name: "Savage"},
    ...> %User{id: 2, first_name: "Pete", last_name: "Funny"}]
    ...> |> EMapper.map(%Employee{id: 1}, Employee,
    ...> id: :ignore!,
    ...> short_name: :first_name,
    ...> full_name: & &1.first_name <> " " <> &1.last_name)
    [%Employee{id: 1, short_name: "John", full_name: "John Savage"},
      %Employee{id: 2, short_name: "Pete" full_name: "Pete Funny"}]

  ```
  """
  @spec map(
          list(struct),
          term,
          atom,
          list({:after_map! | atom, (term, term -> term) | (term -> term) | :ignore! | atom})
        ) :: list(term)
  def map(elements, item, type, options)
      when is_list(elements) and is_atom(type) and is_list(options) do
    elements |> Enum.map(&map(&1, item, type, options))
  end

  @doc """
  Maps `el` to `item` of `type` instance based on scheme defined in `options`

  ## Parameters:

    - `el` - element to map from

    - `item` - instance of type to map to

    - `type` - type name to map to

    - `options` - key-value list of mapping options:
      * Keys can be:
        - `:after_map!`
        - `type_2`
        - atom representing one of `type_2` property  if it is a struct
      * Values can be:
        - `:ignore!` to ignore property while mapping
        - `fn src, dest -> dest end` for `:after_map!` or `type_2` keys
        - atom representing one of `type_1` properties
        - `fn src -> value end` to calculate value for property

  ## Examples:

  ```elixir
    iex> %User{id: 1, first_name: "John", last_name: "Savage"}
    ...> |> EMapper.map(%Employee{id: 1}, Employee,
    ...> id: :ignore!,
    ...> short_name: :first_name,
    ...> full_name: & &1.first_name <> " " <> &1.last_name)
    %Employee{id: 1, short_name: "John", full_name: "John Savage"}

  ```
  """
  @spec map(
          struct,
          term,
          atom,
          list({:after_map! | atom, (term, term -> term) | (term -> term) | :ignore! | atom})
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

  @doc """
  Reduces `elements` to `type` instance based on previously defined scheme in `add_reduce(...)`

  ## Parameters:

    - `elements` - list of elements to map from

    - `type` - type name to map to

  ## Examples:

  ```elixir
    iex> EMapper.add_reduce(Transaction, Balance, amount: 0, amount: & &2 + &1.amount)
    iex> [%Transaction{id: 1, amount: 20},
    ...> %Transaction{id: 2, amount: -4}]
    ...> |> EMapper.reduce(Balance)
    %Balance{id: nil, amount: 16}

  ```
  """
  @spec reduce(list(struct), atom) :: term
  def reduce(elements, type)
      when is_list(elements) and is_atom(type) do
    case elements do
      [] ->
        Utils.fill_item(nil, type, [])

      elements ->
        opts =
          elements
          |> List.first()
          |> Map.get(:__struct__)
          |> Utils.get_reduce_atom()
          |> Server.get_mapping(type)

        reduce(elements, type, opts)
    end
  end

  @doc """
  Reduces `elements` to `type` instance based on scheme defined in `options`

  ## Parameters:

    - `elements` - list of elements to map from

    - `type` - type name to map to

    - `opts` - key-value list of mapping options:
      * Keys can be:
        - `type_2`
        - any key in `type_2` if it is a struct
      * Values can be:
        - `fn src, value -> value end` - accumulator function
        - `fn src, dest -> dest end` for `type_2` key
        - value - value (will be assigned before first element of reduce list is processed)

  ## Examples:

  ```elixir
    iex> [%Transaction{id: 1, amount: 20},
    ...> %Transaction{id: 2, amount: -4}]
    ...> |> EMapper.reduce(Balance, amount: 0, amount: & &2 + &1.amount)
    %Balance{id: nil, amount: 16}

  ```
  """
  @spec reduce(list(struct), atom, list({atom, (term, term -> term) | term})) :: term
  def reduce(elements, type, options)
      when is_list(elements) and is_atom(type) and is_list(options) do
    reduce(elements, nil, type, options)
  end

  @doc """
  Reduces `elements` to `item` instance of `type` based on previously defined scheme in `add_reduce(...)`

  ## Parameters:

    - `elements` - list of elements to map from

    - `item` - instance of type to map to

    - `type` - type name to map to

  ## Examples:

  ```elixir
    iex> EMapper.add_reduce(Transaction, Balance, amount: & &2 + &1.amount)
    iex> [%Transaction{id: 1, amount: 20}, %Transaction{id: 2, amount: -150}]
    ...> |> EMapper.reduce(%Balance{id: 1, amount: 400}, Balance)
    %Balance{id: 1, amount: 400 + 20 - 150}

  ```
  """
  @spec reduce(list(struct), term, atom) :: term
  def reduce(elements, item, type)
      when is_list(elements) and is_atom(type) do
    case elements do
      [] ->
        Utils.fill_item(item, type, [])

      elements ->
        opts =
          elements
          |> List.first()
          |> Map.get(:__struct__)
          |> Utils.get_reduce_atom()
          |> Server.get_mapping(type)

        reduce(elements, item, type, opts)
    end
  end

  @doc """
  Reduces `elements` to `item` instance of `type` based on scheme defined in `options`

  ## Parameters:

    - `elements` - list of elements to map from

    - `item` - instance of type to map to

    - `type` - type name to map to

    - `opts` - key-value list of mapping options:
      * Keys can be:
        - `type_2`
        - any key in `type_2` if it is a struct
      * Values can be:
        - `fn src, value -> value end` - accumulator function
        - `fn src, dest -> dest end` for `type_2` key
        - value - value (will be assigned before first element of reduce list is processed)

  ## Examples:

  ```elixir
    iex> [%Transaction{id: 1, amount: 20}, %Transaction{id: 2, amount: -150}]
    ...> |> EMapper.reduce(%Balance{id: 1, amount: 400}, Balance, amount: & &2 + &1.amount)
    %Balance{id: 1, amount: 400 + 20 - 150}

  ```
  """
  @spec reduce(list(struct), term, atom, list({atom, (term, term -> term) | term})) :: term
  def reduce(elements, item, type, options)
      when is_list(elements) and is_atom(type) and is_list(options) do
    elements
    |> Enum.reduce(
      item |> Utils.fill_item(type, options),
      &Utils.reduce(&1, &2, type, options)
    )
  end
end
