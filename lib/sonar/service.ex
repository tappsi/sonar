defmodule Sonar.Service do
  @moduledoc """
  RPC API for interacting with sonar registered services
  """

  @timeout :timer.seconds(5)

  # API

  @doc """
  Evaluates `apply(mod, fun, args)` on `service` node and returns the
  corresponding value `res`, or `{:error, {:badrpc, reason}` if the
  call fails
  """
  def call({service, key}, mod, fun, args, timeout \\ @timeout) do
    with_node({service, key}, &do_call(service, &1, mod, fun, args, timeout))
  end

  @doc """
  Evaluates `apply(mod, fun, args)` on node for `service` hashed by
  `key`
  """
  def cast({service, key}, mod, fun, args) do
    with_node({service, key}, &do_cast(service, &1, mod, fun, args))
  end

  @doc """
  Implements call streams with promises, a type of RPC that does not
  suspend the caller until the result is finished. Instead, a key is
  returned, which can be used later to collect the value. The key can
  be viewed as a promise to deliver the answer
  """
  def async_call({service, key}, mod, fun, args) do
    with_node({service, key}, &do_async_call(service, &1, mod, fun, args))
  end

  @doc """
  Returns the promised answer from a previous `async_call/4`
  """
  def yield(key),
    do: :gen_rpc.yield(key) |> parse_reply({:undefined, :undefined})

  @doc "Non-blocking version of yield/1"
  def nb_yield(key),
    do: :gen_rpc.nb_yield(key) |> parse_reply({:undefined, :undefined})

  def nb_yield(key, timeout),
    do: :gen_rpc.nb_yield(key, timeout) |> parse_reply({:undefined, :undefined})

  @doc """
  The function evaluates `apply(mod, fun, args)` on the specified
  nodes for `service` and collects the answers

  It returns `{res_l, bad_nodes}`, where `bad_nodes` is a list of the
  nodes that terminated or timed out during computation, and `res_l`
  is a list of the return values. `timeout` is a time (integer) in
  milliseconds, or infinity.
  """
  def multicall(service_req, mod, fun, args, timeout \\ :infinity)
  def multicall({service, key, n}, mod, fun, args, timeout) do
    with_nodes({service, key, n},
      &do_multicall(service, &1, mod, fun, args, timeout))
  end
  def multicall(service, mod, fun, args, timeout) do
    with_nodes(service, &do_multicall(service, &1, mod, fun, args, timeout))
  end

  @doc """
  Evaluates `apply(mod, fun, args)` on the specified nodes for
  `service`. No answers are collected
  """
  def multicast({service, key, n}, mod, fun, args) do
    with_nodes({service, key, n}, &do_multicast(service, &1, mod, fun, args))
  end
  def multicast(service, mod, fun, args) do
    with_nodes(service, &do_multicast(service, &1, mod, fun, args))
  end

  @doc """
  Broadcasts the message `msg` asynchronously to the registered process
  `name` in `n` nodes for `service` hashed by `key`
  """
  def abcast({service, key, n}, name, msg) do
    with_nodes({service, key, n}, &do_abcast(service, &1, name, msg))
  end
  def abcast(service, name, msg) do
    with_nodes(service, &do_abcast(service, &1, name, msg))
  end

  @doc """
  Broadcasts the message `msg` synchronously to the registered process
  `name` on the specified nodes for `service`

  Returns `{good_nodes, bad_nodes}`, where `good_nodes` is the list of
  nodes that have `name` as a registered process.
  """
  def sbcast({service, key, n}, name, msg) do
    with_nodes({service, key, n}, &do_sbcast(service, &1, name, msg))
  end
  def sbcast(service, name, msg) do
    with_nodes(service, &do_sbcast(service, &1, name, msg))
  end

  # Internal functions

  defp do_call(service, node, mod, fun, args, timeout) do
    :gen_rpc.call(node, mod, fun, args, timeout)
    |> parse_reply({service, node})
  end

  defp do_cast(service, node, mod, fun, args) do
    :gen_rpc.cast(node, mod, fun, args)
    |> parse_reply({service, node})
  end

  defp do_async_call(service, node, mod, fun, args) do
    :gen_rpc.async_call(node, mod, fun, args)
    |> parse_reply({service, node})
  end

  defp do_multicall(service, nodes, mod, fun, args, timeout) do
    :gen_rpc.multicall(nodes, mod, fun, args, timeout)
    |> parse_reply({service, nodes})
  end

  defp do_multicast(service, nodes, mod, fun, args) do
    :gen_rpc.eval_everywhere(nodes, mod, fun, args)
    |> parse_reply({service, nodes})
  end

  defp do_abcast(service, nodes, name, msg) do
    :gen_rpc.abcast(nodes, name, msg)
    |> parse_reply({service, nodes})
  end

  defp do_sbcast(service, nodes, name, msg) do
    :gen_rpc.sbcast(nodes, name, msg)
    |> parse_reply({service, nodes})
  end

  def with_node({service, key}, fun) do
    case Sonar.find_service(service, key) do
      {:error, _} = error -> error
      node -> fun.(node)
    end
  end

  defp with_nodes({service, key, n}, fun) do
    case Sonar.find_service(service, key, n) do
      {:error, _} = error -> error
      nodes -> fun.(nodes)
    end
  end
  defp with_nodes(service, fun) do
    service
    |> Sonar.online_services()
    |> Enum.map(fn {node, _meta} -> node end)
    |> fun.()
  end

  defp parse_reply({:badrpc, _} = error, dest), do: {:error, error, dest}
  defp parse_reply({:badtcp, _} = error, dest), do: {:error, error, dest}
  defp parse_reply(true, dest),                 do: {:ok, dest}
  defp parse_reply(:abcast, dest),              do: {:ok, dest}
  defp parse_reply(:sbcast, dest),              do: {:ok, dest}
  defp parse_reply(reply, dest),                do: {:ok, reply, dest}
end
