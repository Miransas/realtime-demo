defmodule Realtime.PostgresListener do
  @moduledoc """
  Listens to PostgreSQL NOTIFY channel(s) and broadcasts events to Phoenix.PubSub.

  To use triggers that emit NOTIFY payloads, see `examples/pg_trigger.sql`.
  Expected payload (JSON) example:
    {"action":"insert","table":"messages","topic":"room:global","payload":{...}}
  """

  use GenServer
  require Logger

  @default_channel "realtime:changes"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    conn_opts = Application.get_env(:realtime, :postgres, [])
    channel = Application.get_env(:realtime, :pg_channel, @default_channel)

    case Postgrex.Notifications.start_link(conn_opts) do
      {:ok, pid} ->
        ref = Postgrex.Notifications.listen!(pid, channel)
        Logger.info("PostgresListener subscribed to #{channel}")
        {:ok, Map.merge(state, %{pid: pid, ref: ref, channel: channel})}

      {:error, reason} ->
        Logger.error("PostgresListener failed to start: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_info({:notification, _pid, _ref, channel, payload}, state) do
    Logger.debug("Received notification on #{channel}: #{inspect(payload)}")
    case Jason.decode(payload) do
      {:ok, data} ->
        event = normalize_event(data)
        topic = Map.get(event, :topic, "room:global")
        Phoenix.PubSub.broadcast(Realtime.PubSub, topic, {:realtime, event})
        {:noreply, state}

      {:error, _} ->
        Logger.warn("PostgresListener: failed to decode payload: #{inspect(payload)}")
        {:noreply, state}
    end
  end

  def handle_info(msg, state) do
    Logger.debug("PostgresListener received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp normalize_event(%{"action" => action, "table" => table, "payload" => payload} = data) do
    %{
      event_type: action,
      table: table,
      payload: payload,
      topic: Map.get(data, "topic") || "table:#{table}",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  defp normalize_event(other) do
    %{
      event_type: Map.get(other, "action", "db_change"),
      table: Map.get(other, "table"),
      payload: Map.get(other, "payload", other),
      topic: Map.get(other, "topic", "room:global"),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end
end
