defmodule Sonar do
  @moduledoc """
  Sonar RPC
  """

  @tracker Sonar.Echo

  alias Phoenix.Tracker
  alias Sonar.HashRing

  # API

  @doc "Add a new service `type` with it's current `version`"
  def add_service(type, version, node \\ node()) do
    meta = %{state: :online, version: version}
    Tracker.track(@tracker, self(), type, node, meta)
  end

  @doc "Enable service `type`"
  def enable_service(type, node \\ node()) do
    Tracker.update(@tracker, self(), type, node, &toggle_state/1)
  end

  @doc "Disable service `type`"
  def disable_service(type, node \\ node()) do
    Tracker.update(@tracker, self(), type, node, &toggle_state/1)
  end

  @doc "Remove service `type`"
  def remove_service(type, node \\ node()) do
    Tracker.untrack(@tracker, self(), type, node)
  end

  @doc "Return all service registrations for `type`"
  def get_services(type) do
    Tracker.list(@tracker, type)
  end

  @doc "Return all online services for `type`"
  def online_services(type) do
    get_services(type)
    |> Enum.filter(fn {_node, meta} -> meta.state == :online end)
  end

  @doc "Return the node for service `type` hashed by `key`"
  def find_service(type, key) do
    with {:ok, selected_node} <- HashRing.whereis(type, key),
      do: selected_node
  end

  @doc "Return `count` near nodes for service `type` hashed by `key`"
  def find_service(type, key, count) do
    with {:ok, nodes} <- HashRing.collect(type, key, count),
      do: nodes
  end

  # Internal functions

  defp toggle_state(%{state: :online} = meta),  do: %{meta | state: :offline}
  defp toggle_state(%{state: :offline} = meta), do: %{meta | state: :online}
end
