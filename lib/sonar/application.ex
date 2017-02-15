defmodule Sonar.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    echo =
      :sonar
      |> Application.get_env(:echo, [])
      |> Keyword.put_new(:name, Sonar.Echo)

    pubsub = Application.get_env(:sonar, :pubsub, [])
    opts = [pubsub[:name] || Phoenix.PubSub.Test.PubSub,
            pubsub[:opts] || []]

    children = [
      supervisor(Sonar.RingSupervisor, []),
      supervisor(Task.Supervisor, [[name: Sonar.TaskSupervisor]]),
      supervisor(Registry, [:unique, Sonar.RingRegistry]),
      supervisor(pubsub[:adapter] || Phoenix.PubSub.PG2, opts),
      worker(Sonar.Echo, [echo])
    ]

    opts = [strategy: :one_for_one, name: Sonar.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
