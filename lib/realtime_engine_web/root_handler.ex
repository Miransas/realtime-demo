defmodule RealtimeEngineWeb.RootHandler do
  @behaviour :cowboy_handler
  require Logger

  def init(req, _opts) do
    case serve_index() do
      {:ok, body} ->
        headers = [{"content-type", "text/html; charset=utf-8"}]
        {:ok, req2} = :cowboy_req.reply(200, headers, body, req)
        {:ok, req2, %{}}

      {:error, reason} ->
        Logger.error("RootHandler failed to read index: #{inspect(reason)}")
        {:ok, req2} = :cowboy_req.reply(500, %{"content-type" => "text/plain"}, "internal error", req)
        {:ok, req2, %{}}
    end
  end

  defp serve_index do
    priv = :code.priv_dir(:realtime_engine)
    path = Path.join(priv, "static/index.html")
    case File.read(path) do
      {:ok, body} -> {:ok, body}
      error -> error
    end
  end
end
