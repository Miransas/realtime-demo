defmodule Realtime.WSHandler do
  @behaviour :cowboy_websocket

  require Logger

  alias Phoenix.PubSub

  def init(req, _opts) do
    {:cowboy_websocket, req, %{topics: MapSet.new()}}
  end

  def websocket_init(state) do
    Logger.info("WebSocket connected")
    {:ok, state}
  end

  # Client messages are expected to be JSON with an `action` field
  # actions: subscribe/unsubscribe/publish
  def websocket_handle({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, %{"action" => "subscribe", "topic" => topic}} ->
        :ok = PubSub.subscribe(Realtime.PubSub, topic)
        new_state = %{state | topics: MapSet.put(state.topics, topic)}
        reply = %{status: "subscribed", topic: topic}
        {:reply, {:text, Jason.encode!(reply)}, new_state}

      {:ok, %{"action" => "unsubscribe", "topic" => topic}} ->
        :ok = PubSub.unsubscribe(Realtime.PubSub, topic)
        new_state = %{state | topics: MapSet.delete(state.topics, topic)}
        reply = %{status: "unsubscribed", topic: topic}
        {:reply, {:text, Jason.encode!(reply)}, new_state}

      {:ok, %{"action" => "publish", "topic" => topic, "payload" => payload}} ->
        event = %{
          event_type: "client_publish",
          payload: payload,
          timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
        }
        PubSub.broadcast(Realtime.PubSub, topic, {:realtime, event})
        {:ok, state}

      _ ->
        {:reply, {:text, Jason.encode!(%{error: "invalid_message"})}, state}
    end
  end

  def websocket_handle({:binary, _bin}, state), do: {:ok, state}

  # Messages from PubSub arrive as {:realtime, event}
  def websocket_info({:realtime, event}, state) do
    payload = %{
      event_type: Map.get(event, :event_type) || Map.get(event, "event_type"),
      payload: Map.get(event, :payload) || Map.get(event, "payload"),
      timestamp: Map.get(event, :timestamp) || Map.get(event, "timestamp") || DateTime.utc_now() |> DateTime.to_iso8601()
    }

    {:reply, {:text, Jason.encode!(payload)}, state}
  end

  def websocket_info(_info, state), do: {:ok, state}

  def terminate(_reason, _req, state) do
    # Cleanup subscriptions
    Enum.each(state.topics, fn topic ->
      try do
        PubSub.unsubscribe(Realtime.PubSub, topic)
      rescue
        _ -> :ok
      end
    end)

    :ok
  end
end
