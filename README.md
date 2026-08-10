# Realtime (Elixir + Cowboy WebSocket)


Minimal production-friendly realtime service using PostgreSQL LISTEN/NOTIFY and Phoenix.PubSub.


Quick start (local with Docker)

1. Start services with Docker Compose (this will run Postgres and start the Elixir app in the container):

```bash
docker compose up --build
```

2. Or run locally if you have Elixir installed:

```bash
export PG_HOST=localhost
export PG_USER=postgres
export PG_PASS=postgres
export PG_DB=realtime_db
export PG_CHANNEL=realtime_events

mix deps.get
mix compile
mix run --no-halt
```

Server listens on the port configured in `config/config.exs` (default `4000`) at `/` (http://localhost:4000/) and websocket endpoint `/socket` (ws://localhost:4000/socket).

WebSocket protocol (JSON):

- Subscribe: {"action":"subscribe","topic":"room:global"}
- Unsubscribe: {"action":"unsubscribe","topic":"room:global"}
- Publish (client->server): {"action":"publish","topic":"room:global","payload":{...}}

Broadcast messages (server->client) are JSON with fields: `event_type`, `payload`, `timestamp`.

Example DB trigger that emits NOTIFY with JSON payload: `examples/pg_trigger.sql`.

