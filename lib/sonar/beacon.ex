defmodule Sonar.Beacon do
  @moduledoc """
  Service beacon
  """

  use GenServer

  # API

  def start_link(service, version, port, protocol, name) when is_atom(name) do
    args = [service, version, port, protocol]
    GenServer.start_link(__MODULE__, args, name: name)
  end

  # GenServer callbacks

  def init([service, version, port, protocol]) do
    Sonar.add_service(service, version, port, protocol)
    {:ok, %{service: service, version: version,
            port: port, protocol: protocol}}
  end
end
