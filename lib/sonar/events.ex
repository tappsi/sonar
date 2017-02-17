defmodule Sonar.Events do
  @moduledoc """
  Sonar event dispatcher
  """

  require Logger

  @doc "Notify a local `pid` with `event`"
  def notify({pid, node}, event) when node == node() do
    Kernel.send(pid, event)
  end
  def notify({pid, node}, event) do
    Logger.warn "got event #{inspect event} from #{inspect {pid, node}}"
    :noop
  end
end
