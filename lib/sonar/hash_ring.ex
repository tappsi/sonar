defmodule Sonar.HashRing do
  @moduledoc """
  Hash ring API
  """

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
    new_ring(service)
  end

  @doc "Add `node` with it's `data` to the `service` hash ring"
  def add_node(service, node, data \\ []) do
    add(service, node, data)
  end

  @doc "Remove `node` from the `service` hash ring"
  def remove_node(service, node) do
    remove(service, node)
  end

  @doc "Get the node for a given `service` hashed by `item`"
  def whereis(service, item) do
    find_node(service, item)
  end

  @doc "Collect `n` nodes for a given `service` hashed by `item`"
  def collect(service, item, n) do
    find_nodes(service, item, n)
  end

  @doc "Return all nodes for a given `service`"
  def nodes(service) do
    ring_nodes(service)
  end

  # Internal functions

  defp ring_nodes(service) do
    with {:ok, ring} <- get(service) do
      {:ok, :hash_ring.get_nodes(ring)}
    end
  end

  defp find_node(service, item) do
    with {:ok, ring} <- get(service) do
      case :hash_ring.find_node(item, ring) do
        {:ok, {_, selected, _, _}} -> {:ok, selected}
        :error -> {:error, :nonode}
      end
    end
  end

  defp find_nodes(service, item, n) do
    with {:ok, ring} <- get(service) do
      item
      |> :hash_ring.collect_nodes(n, ring)
      |> Enum.map(fn {_, selected, _, _} -> selected end)
    end
  end

  defp new_ring(service) do
    ring = :hash_ring.make([])
    true = :ets.insert_new(:sonar_rings, {service, ring})
    :ok
  end

  defp add(service, new_node, data) do
    case :ets.lookup(:sonar_rings, service) do
      [] -> {:error, :noring}
      [{^service, ring}] ->
        new_ring =
          new_node
          |> :hash_ring_node.make(data)
          |> :hash_ring.add_node(ring)
        true = :ets.insert(:sonar_rings, {service, new_ring})
        :ok
    end
  end

  defp remove(service, old_node) do
    case :ets.lookup(:sonar_rings, service) do
      [] -> {:error, :noring}
      [{^service, ring}] ->
        updated_ring = :hash_ring.remove_node(old_node, ring)
        true = :ets.insert(:sonar_rings, {service, updated_ring})
        :ok
    end
  end

  defp get(service) do
    case :ets.lookup(:sonar_rings, service) do
      [] -> {:error, :service_not_found}
      [{^service, ring}] -> {:ok, ring}
    end
  end
end
