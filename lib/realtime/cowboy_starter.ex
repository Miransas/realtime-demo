defmodule Realtime.CowboyStarter do
  @moduledoc "Start and supervise the Cowboy listener"
  use GenServer

  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    port = Application.get_env(:realtime, :port, 4000)
    dispatch = :cowboy_router.compile([{:_, [{"/ws", Realtime.WSHandler, []}]}])

    case :cowboy.start_clear(:http_listener, [{:port, port}], %{env: %{dispatch: dispatch}}) do
      {:ok, _pid} ->
        Logger.info("Cowboy started on port #{port}")
        {:ok, state}

      {:error, reason} ->
        Logger.error("Failed to start Cowboy: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  def terminate(_reason, _state) do
    try do
      :cowboy.stop_listener(:http_listener)
    rescue
      _ -> :ok
    end

    :ok
  end
end
