defmodule Sonar.Mixfile do
  use Mix.Project

  @version File.read!("VERSION") |> String.strip

  def project do
    [app: :sonar,
     name: "Sonar",
     source_url: "https://github.com/tappsi/sonar",
     homepage_url: "https://github.com/tappsi/sonar",
     version: @version,
     elixir: "~> 1.4",
     description: description(),
     docs: docs(),
     package: package(),
     test_coverage: [tool: ExCoveralls],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger],
     mod: {Sonar.Application, []}]
  end

  defp description do
    "Scalable service discovery and RPC library"
  end

  def docs do
    [source_ref: "v#{@version}",
     main: "Sonar",
     extras: ["README.md", "CONTRIBUTING.md", "CHANGELOG.md"]]
  end

  defp package do
    [files: ~w(lib test mix.exs README.md LICENSE VERSION),
     maintainers: ["Oscar Moreno", "Ricardo Lanziano"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/tappsi/sonar"}]
  end

  defp deps do
    [{:phoenix_pubsub, "~> 1.0"},
     {:hash_ring, "~> 0.4"},
     {:gen_rpc, "~> 2.1"},

     # Development
     {:excoveralls, "> 0.0.0", only: :test},

     # Documentation
     {:ex_doc, "> 0.0.0", only: :docs},
     {:earmark, "> 0.0.0", only: :docs}]
  end
end
