defmodule RealtimeEngine.Repo do
  @moduledoc "Minimal Postgrex connection manager for queries when needed."
  use GenServer
  require Logger

  @connect_backoff 5000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    opts = Application.get_env(:realtime_engine, :postgres, [])
    state = Map.put(state, :opts, opts)
    connect(state)
  end

  defp connect(state) do
    opts = Map.get(state, :opts)
    case Postgrex.start_link(opts) do
      {:ok, pid} ->
        Logger.info("RealtimeEngine.Repo connected to Postgres")
        {:ok, %{state | pid: pid, backoff: @connect_backoff}}

      {:error, reason} ->
        Logger.error("RealtimeEngine.Repo failed to connect: #{inspect(reason)} - retrying in #{@connect_backoff}ms")
        Process.send_after(self(), :retry_connect, @connect_backoff)
        {:ok, %{state | pid: nil, backoff: @connect_backoff}}
    end
  end

  @impl true
  def handle_info(:retry_connect, state) do
    connect(state)
  end

  @impl true
  def handle_call({:query, sql, params}, _from, %{pid: pid} = state) when is_pid(pid) do
    result = Postgrex.query(pid, sql, params)
    {:reply, result, state}
  end

  def handle_call({:query, _sql, _params}, _from, state) do
    {:reply, {:error, :not_connected}, state}
  end

  @doc "Execute a simple query via the repo process. Returns Postgrex result or error."
  def query(sql, params \ []) do
    GenServer.call(__MODULE__, {:query, sql, params})
  end
end
