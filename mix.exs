defmodule RealtimeEngine.MixProject do
  use Mix.Project

  def project do
    [
      app: :realtime_engine,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {RealtimeEngine.Application, []}
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.6"},
      {:phoenix_pubsub, "~> 2.1"},
      {:postgrex, ">= 0.15.13"},
      {:jason, "~> 1.4"}
    ]
  end
end
