defmodule Sonar.RingSupervisor do
  @moduledoc false

  use Supervisor

  @name __MODULE__

  # API

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  # Supervisor callbacks

  def init(_args) do
    child = worker(Sonar.HashRing, [], restart: :transient)
    supervise([child], [strategy: :simple_one_for_one])
  end
end

defmodule Sonar.HashRing do
  @moduledoc """
  Hash ring API
  """

  use GenServer

  require Logger

  @name       __MODULE__
  @supervisor Sonar.RingSupervisor
  @registry   Sonar.RingRegistry

  # API

  @doc "Check if `service` hash ring exists"
  def exists?(service) do
    case get(service) do
      {:ok, _}    -> true
      {:error, _} -> false
    end
  end

  @doc "Create a new hash ring for `service`"
  def create(service) do
    Supervisor.start_child(@supervisor, [service])
  end

  @doc "Add `node` with it's `data` to the `service` hash ring"
  def add_node(service, node, data \\ []) do
    with {:ok, pid} <- get(service) do
      GenServer.call(pid, {:add_node, node, data})
    end
  end

  @doc "Remove `node` from the `service` hash ring"
  def remove_node(service, node) do
    with {:ok, pid} <- get(service) do
      GenServer.call(pid, {:remove_node, node})
    end
  end

  @doc "Get the node for a given `service` hashed by `item`"
  def whereis(service, item) do
    with {:ok, pid} <- get(service) do
      GenServer.call(pid, {:whereis, item})
    end
  end

  @doc "Collect `n` nodes for a given `service` hashed by `item`"
  def collect(service, item, n) do
    with {:ok, pid} <- get(service) do
      GenServer.call(pid, {:collect, item, n})
    end
  end

  @doc "Return all nodes for a given `service`"
  def nodes(service) do
    with {:ok, pid} <- get(service) do
      GenServer.call(pid, :get_nodes)
    end
  end

  @doc "Starts and links a new hash ring for `service`"
  def start_link(service) do
    GenServer.start_link(@name, [service], name: via(service))
  end

  # GenServer callbacks

  def init([service]) do
    {:ok, %{ring: new_ring(), service: service}}
  end

  def handle_call({:add_node, new_node, data}, _from, %{ring: ring} = state) do
    {:reply, :ok, %{state | ring: add(ring, new_node, data)}}
  end
  def handle_call({:remove_node, down_node}, _from, %{ring: ring} = state) do
    {:reply, :ok, %{state | ring: remove(ring, down_node)}}
  end
  def handle_call(:get_nodes, _from, %{ring: ring} = state) do
    reply = {:ok, :hash_ring.get_nodes(ring)}
    {:reply, reply, state}
  end
  def handle_call({:whereis, item}, _from, %{ring: ring} = state) do
    reply =
      case :hash_ring.find_node(item, ring) do
        {:ok, {_, selected_node, _, _}} -> {:ok, selected_node}
        :error -> {:error, :nonode}
      end
    {:reply, reply, state}
  end
  def handle_call({:collect, item, n}, _from, %{ring: ring} = state) do
    nodes =
      item
      |> :hash_ring.collect_nodes(n, ring)
      |> Enum.map(fn {_, selected_node, _, _} -> selected_node end)
    {:reply, nodes, state}
  end

  # Internal functions

  defp new_ring, do: :hash_ring.make([])

  defp add(ring, new_node, data) do
    new_node
    |> :hash_ring_node.make(data)
    |> :hash_ring.add_node(ring)
  end

  defp remove(ring, old_node),
    do: :hash_ring.remove_node(old_node, ring)

  defp via(service), do: {:via, Registry, {@registry, service}}

  defp get(service) when is_pid(service), do: {:ok, service}
  defp get(service) do
    case Registry.lookup(@registry, service) do
      [] -> {:error, :service_not_found}
      [{pid, _}] -> {:ok, pid}
    end
  end
end
