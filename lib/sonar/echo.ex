defmodule Sonar.Echo do
  @moduledoc """
  Sonar tracker behaviour
  """

  @behaviour Phoenix.Tracker

  @name __MODULE__

  alias Phoenix.{PubSub, Tracker}
  alias Sonar.{HashRing, NodeConfig}

  # API

  def start_link(opts \\ []) do
    pubsub_server = Keyword.get(opts, :pubsub, Sonar.PubSub)
    full_opts = Keyword.merge([name: @name,
                               pubsub_server: pubsub_server], opts)
    GenServer.start_link(Tracker, [__MODULE__, full_opts, full_opts], opts)
  end

  # Tracker callbacks

  def init(opts) do
    {:ok, %{pubsub: Keyword.fetch!(opts, :pubsub_server)}}
  end

  def handle_diff(diff, %{pubsub: pubsub} = state) do
    for {type, {joins, leaves}} <- diff do
      unless HashRing.exists?(type) do
        :ok  = HashRing.create(type)
      end

      for {lnode, meta} <- leaves do
        unless Enum.any?(joins,
          fn({jnode, %{state: state}}) -> jnode == lnode && state == :online end) do
          :ok = HashRing.remove_node(type, lnode)
        end

        PubSub.direct_broadcast(node(), pubsub, type, {:leave, lnode, meta})
      end
      for {jnode, meta} <- joins do
        case meta.state do
          :online  ->
            :ok = HashRing.add_node(type, jnode)
            :ok = NodeConfig.update_mapping(jnode, meta.protocol, meta.port)
          :offline -> :ok
        end

        PubSub.direct_broadcast(node(), pubsub, type, {:join, jnode, meta})
      end
    end

    {:ok, state}
  end
end
