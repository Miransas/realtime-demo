defmodule RealtimeEngineWeb.Endpoint do
  @moduledoc "Plug Router that serves static files from priv/static"
  use Plug.Router

  plug Plug.Logger
  plug Plug.Static, at: "/", from: {:realtime_engine, "priv/static"}, only: ~w(index.html)
  plug :match
  plug :dispatch

  get "/" do
    send_file(conn, 200, Path.join(:code.priv_dir(:realtime_engine), "static/index.html"))
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end
