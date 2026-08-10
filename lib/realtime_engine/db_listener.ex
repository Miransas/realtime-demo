defmodule RealtimeEngine.DbListener do
  @moduledoc "Listen to Postgres NOTIFY channel and broadcast via Phoenix.PubSub"
  use GenServer
  require Logger

  @default_channel "realtime_events"
  @reconnect_initial 1_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    opts = Application.get_env(:realtime_engine, :postgres, [])
    channel = Application.get_env(:realtime_engine, :pg_channel, @default_channel)
    Process.flag(:trap_exit, true)
    state = %{state | opts: opts, channel: channel, backoff: @reconnect_initial, mon_ref: nil}
    send(self(), :connect)
    {:ok, state}
  end

  def handle_info(:connect, %{opts: opts, channel: channel} = state) do
    case Postgrex.Notifications.start_link(opts) do
      {:ok, pid} ->
        try do
          # monitor and listen
          mon_ref = Process.monitor(pid)
          Postgrex.Notifications.listen!(pid, channel)
          Logger.info("DbListener subscribed to #{channel}")
          {:noreply, %{state | pid: pid, mon_ref: mon_ref, backoff: @reconnect_initial}}
        rescue
          e ->
            Logger.error("Failed to listen on #{channel}: #{inspect(e)}")
            Process.send_after(self(), :connect, state.backoff)
            {:noreply, %{state | backoff: min(state.backoff * 2, 60_000)}}
        end

      {:error, reason} ->
        Logger.error("DbListener can't start notifications: #{inspect(reason)}; retrying in #{state.backoff}ms")
        Process.send_after(self(), :connect, state.backoff)
        {:noreply, %{state | pid: nil, backoff: min(state.backoff * 2, 60_000)}}
    end
  end

  def handle_info({:notification, _pid, _ref, channel, payload}, state) do
    Logger.debug("Notification on #{channel}: #{inspect(payload)}")
    case Jason.decode(payload) do
      {:ok, data} when is_map(data) ->
        event = build_event(data)
        topic = Map.get(event, :topic, "room:global")
        Phoenix.PubSub.broadcast(RealtimeEngine.PubSub, topic, {:db_change, event})
        {:noreply, state}

      {:error, _} ->
        Logger.warn("DbListener: invalid JSON payload: #{inspect(payload)}")
        {:noreply, state}
    end
  end

  # If notifications connection exits, try reconnect
  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    Logger.warn("DbListener notifications connection down: #{inspect(reason)}, reconnecting")
    Process.send_after(self(), :connect, state.backoff)
    {:noreply, %{state | pid: nil, mon_ref: nil, backoff: min(state.backoff * 2, 60_000)}}
  end

  def handle_info({:EXIT, _pid, reason}, state) do
    Logger.warn("DbListener linked process exited: #{inspect(reason)}, reconnecting")
    Process.send_after(self(), :connect, state.backoff)
    {:noreply, %{state | pid: nil, mon_ref: nil, backoff: min(state.backoff * 2, 60_000)}}
  end

  def handle_info(msg, state) do
    Logger.debug("DbListener received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp build_event(%{"action" => action, "table" => table, "payload" => payload} = data) do
    %{
      event_type: action,
      table: table,
      payload: payload,
      topic: Map.get(data, "topic") || "table:#{table}",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  defp build_event(other) when is_map(other) do
    %{
      event_type: Map.get(other, "action", "db_change"),
      table: Map.get(other, "table"),
      payload: Map.get(other, "payload", other),
      topic: Map.get(other, "topic", "room:global"),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end
end
