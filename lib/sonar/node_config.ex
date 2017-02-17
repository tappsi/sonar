defmodule Sonar.NodeConfig do
  @moduledoc """
  Node configuration API
  """

  @doc "Updates the configuration mapping for `node`"
  def update_mapping(node, protocol, port) do
    {:internal, config} = Application.get_env(:gen_rpc, :client_config_per_node)
    config = Map.put(config, node, {protocol, port})
    Application.put_env(:gen_rpc, :client_config_per_node, {:internal, config})
    :ok
  end
end
