defmodule RealtimeEngineWeb.SocketHandler do
  @behaviour :cowboy_websocket
  require Logger
  alias Phoenix.PubSub

  @impl true
  def init(req, _opts) do
    {:cowboy_websocket, req, %{topics: MapSet.new(), peer: peer(req)}}
  end

  defp peer(req) do
    case :cowboy_req.peer(req) do
      {ip, port} when is_tuple(ip) and is_integer(port) ->
        "#{:inet_parse.ntoa(ip)}:#{port}"
      _ ->
        "unknown"
    end
  end

  @impl true
  def websocket_init(state) do
    Logger.info("Socket connected: #{state.peer}")
    {:ok, state}
  end

  @impl true
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

      {:ok, other} ->
        Logger.warn("Unknown client action: #{inspect(other)}")
        {:reply, {:text, Jason.encode!(%{error: "unknown_action"})}, state}

      {:error, _} ->
        Logger.warn("Invalid JSON from client: #{inspect(msg)}")
        {:reply, {:text, Jason.encode!(%{error: "invalid_json"})}, state}
    end
  end



  @impl true
  def websocket_handle({:binary, _}, state), do: {:ok, state}

  @impl true
  def websocket_info({:db_change, event}, state) do
    payload = %{
      event: "db_change",
      payload: event,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    {:reply, {:text, Jason.encode!(payload)}, state}
  rescue
    e ->
      Logger.error("websocket_info error: #{inspect(e)}")
      {:ok, state}
  end

  def websocket_info(_info, state), do: {:ok, state}

  @impl true
  def terminate(_reason, _req, state) do
    Enum.each(state.topics, fn topic ->
      try do
        PubSub.unsubscribe(RealtimeEngine.PubSub, topic)
      rescue
        _ -> :ok
      end
    end)

    Logger.info("Socket terminated: #{state.peer}")
    :ok
  end
end
