defmodule Sonar.Mixfile do
  use Mix.Project

  def project do
    [app: :sonar,
     version: "0.1.1",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger],
     mod: {Sonar.Application, []}]
  end

  defp deps do
    [{:phoenix_pubsub, "~> 1.0"},
     {:hash_ring, "~> 0.4"},
     {:gen_rpc, "~> 2.1"}]
  end
end
