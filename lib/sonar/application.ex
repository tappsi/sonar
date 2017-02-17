defmodule Sonar.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    srv = Application.get_env(:sonar, :service)

    Application.stop(:gen_rpc)

    :ok = Application.put_env(:gen_rpc, :tcp_client_port, srv[:client])
    :ok = Application.put_env(:gen_rpc, :tcp_server_port, srv[:port])
    :ok = Application.put_env(:gen_rpc, :default_client_driver, srv[:protocol])

    Application.start(:gen_rpc)

    echo =
      :sonar
      |> Application.get_env(:echo, [])
      |> Keyword.put_new(:name, Sonar.Echo)

    pubsub = Application.get_env(:sonar, :pubsub, [])
    opts = [pubsub[:name] || Phoenix.PubSub.Test.PubSub,
            pubsub[:opts] || []]

    :sonar_rings = :ets.new(:sonar_rings, [:named_table, :public,
                                           read_concurrency: true])

    children = [
      supervisor(Task.Supervisor, [[name: Sonar.TaskSupervisor]]),
      supervisor(pubsub[:adapter] || Phoenix.PubSub.PG2, opts),
      worker(Sonar.Echo, [echo])
    ]

    opts = [strategy: :one_for_one, name: Sonar.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
