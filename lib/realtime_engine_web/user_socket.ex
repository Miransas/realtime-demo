defmodule RealtimeEngineWeb.UserSocket do
  @behaviour :cowboy_websocket
  require Logger
  alias Phoenix.PubSub

  def init(req, _opts) do
    {:cowboy_websocket, req, %{topics: MapSet.new()}}
  end

  def websocket_init(state) do
    Logger.info("UserSocket connected")
    {:ok, state}
  end

  def websocket_handle({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, %{"action" => "join", "topic" => topic}} when is_binary(topic) ->
        :ok = PubSub.subscribe(RealtimeEngine.PubSub, topic)
        new_state = %{state | topics: MapSet.put(state.topics, topic)}
        {:reply, {:text, Jason.encode!(%{status: "joined", topic: topic})}, new_state}

      {:ok, %{"action" => "leave", "topic" => topic}} when is_binary(topic) ->
        :ok = PubSub.unsubscribe(RealtimeEngine.PubSub, topic)
        new_state = %{state | topics: MapSet.delete(state.topics, topic)}
        {:reply, {:text, Jason.encode!(%{status: "left", topic: topic})}, new_state}

      {:ok, %{"action" => "ping"}} ->
        {:reply, {:text, Jason.encode!(%{event: "pong", timestamp: DateTime.utc_now() |> DateTime.to_iso8601()})}, state}

      {:ok, _} ->
        {:reply, {:text, Jason.encode!(%{error: "unknown_action"})}, state}

      {:error, _} ->
        {:reply, {:text, Jason.encode!(%{error: "invalid_json"})}, state}
    end
  end

  def websocket_handle({:binary, _}, state), do: {:ok, state}

  # Handle messages from PubSub
  def websocket_info({:db_change, event}, state) do
    msg = %{event: "db_change", payload: event}
    {:reply, {:text, Jason.encode!(msg)}, state}
  end

  def websocket_info(_info, state), do: {:ok, state}

  def terminate(_reason, _req, state) do
    Enum.each(state.topics, fn topic ->
      try do
        PubSub.unsubscribe(RealtimeEngine.PubSub, topic)
      rescue
        _ -> :ok
      end
    end)

    :ok
  end
end
