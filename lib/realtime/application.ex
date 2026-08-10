defmodule Realtime.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: Realtime.PubSub},
      Realtime.PostgresListener,
      Realtime.CowboyStarter
    ]

    opts = [strategy: :one_for_one, name: Realtime.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_cowboy do
    dispatch = :cowboy_router.compile([{:_, [{"/ws", Realtime.WSHandler, []}]}])
    {:ok, _} = :cowboy.start_clear(:http, [{:port, Application.get_env(:realtime, :port, 4000)}], %{env: %{dispatch: dispatch}})
    :ok
  end
end
