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

  def add_mapping(type_1, type_2, opts) do
    GenServer.cast(__MODULE__, {:add_mapping, {{type_1, type_2}, opts}})
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
    filter = [{{:"$1", :"$2"}, [{:==, :"$1", {id}}], [:"$2"]}]
    result = Ets.select(__MODULE__, filter) |> Enum.at(0)

    {:reply, result, state}
  end

  @impl true
  def handle_cast({:add_mapping, {{type_1, type_2}, _opts} = data}, state) do
    Logger.debug("Mapping for #{inspect(type_1)} -> #{inspect(type_2)} added")
    Ets.insert_new(__MODULE__, data)

    {:noreply, state}
  end
end
