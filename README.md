# Realtime (Elixir + Cowboy WebSocket)


Minimal production-friendly realtime service using PostgreSQL LISTEN/NOTIFY and Phoenix.PubSub.

Quick start

1. Install dependencies:

```bash
mix deps.get
```

2. Configure PostgreSQL connection via environment variables (optional):

```bash
export PG_HOST=localhost
export PG_USER=postgres
export PG_PASS=yourpass
export PG_DB=yourdb
export PG_CHANNEL=realtime:changes
```

3. Run the server:

```bash
mix run --no-halt
```

Server listens on the port configured in `config/config.exs` (default `4000`) at `/ws` (ws://localhost:4000/ws).

WebSocket protocol (JSON):

- Subscribe: {"action":"subscribe","topic":"room:global"}
- Unsubscribe: {"action":"unsubscribe","topic":"room:global"}
- Publish (client->server): {"action":"publish","topic":"room:global","payload":{...}}

Broadcast messages (server->client) are JSON with fields: `event_type`, `payload`, `timestamp`.

Example DB trigger that emits NOTIFY with JSON payload: `examples/pg_trigger.sql`.

