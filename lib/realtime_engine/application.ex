defmodule RealtimeEngine.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: RealtimeEngine.PubSub},
      RealtimeEngine.Repo,
      RealtimeEngine.DbListener,
      RealtimeEngine.CowboyStarter
    ]

    opts = [strategy: :one_for_one, name: RealtimeEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
