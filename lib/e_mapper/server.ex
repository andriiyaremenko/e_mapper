defmodule EMapper.Server do
  use GenServer
  require Logger

  alias :ets, as: Ets

  # Client
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_mapping(type_1, type_2) do
    case GenServer.call(__MODULE__, {:get_mapping, {type_1, type_2}}) do
      mapping when is_list(mapping) -> mapping
      _ -> []
    end
  end

  @spec add_mapping(atom, atom, list({atom, (term -> term) | :ignore! | atom})) :: :ok | {:error, term}
  def add_mapping(type_1, type_2, opts) do
    GenServer.cast(__MODULE__, {:add_mapping, {{type_1, type_2}, opts}})
  end

  @spec add_mapping(atom, atom, list({atom, (term -> term) | :ignore! | atom}), :reverse_map) :: :ok | {:error, term}
  def add_mapping(type_1, type_2, opts, :reverse_map) do
    reverse_options =
      opts
      |> Enum.filter(fn {_key, value} -> is_atom(value) end)
      |> Enum.map(fn {key, value} ->
        if value == :ignore! do
          {key, value}
        else
          {value, key}
        end
      end)

    with :ok <- GenServer.cast(__MODULE__, {:add_mapping, {{type_1, type_2}, opts}}),
         :ok <- GenServer.cast(__MODULE__, {:add_mapping, {{type_2, type_1}, reverse_options}}) do
      :ok
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  def delete_mappings() do
    GenServer.cast(__MODULE__, :delete_mappings)
  end

  # Server
  @impl true
  def init(_opts) do
    Logger.debug("#{inspect(__MODULE__)} initialized")
    Ets.new(__MODULE__, [:set, :protected, :named_table])

    {:ok, nil}
  end

  @impl true
  def handle_call({:get_mapping, id}, _from, state) do
    result = get_mapping(id)

    {:reply, result, state}
  end

  @impl true
  def handle_cast({:add_mapping, {{type_1, type_2} = id, opts}}, state) do
    Logger.debug("Mapping for #{inspect(type_1)} -> #{inspect(type_2)} added")

    old_mapping =
      get_mapping(id) |> Enum.filter(fn {key, _value} -> !List.keymember?(opts, key, 0) end)

    Ets.delete(__MODULE__, id)
    Ets.insert_new(__MODULE__, {id, old_mapping ++ opts})

    {:noreply, state}
  end

  @impl true
  def handle_cast(:delete_mappings, state) do
    Ets.delete(__MODULE__)
    Ets.new(__MODULE__, [:set, :protected, :named_table])

    {:noreply, state}
  end

  defp get_mapping(id) do
    filter = [{{:"$1", :"$2"}, [{:==, :"$1", {id}}], [:"$2"]}]
    Ets.select(__MODULE__, filter) |> Enum.at(0, [])
  end
end
