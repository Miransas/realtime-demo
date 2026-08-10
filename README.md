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

Docker installation

If you don't have Docker installed, follow the platform-specific instructions below.

- macOS (recommended: Homebrew + Docker Desktop):

```bash
brew install --cask docker
# then open Docker.app from Applications and wait until it starts
```

- Ubuntu / Debian (via apt):

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable --now docker
```

- Windows: install Docker Desktop from https://www.docker.com/get-started and follow the installer.

If you prefer not to install Docker, you can run Postgres locally and run the Elixir app directly (see Local run instructions above).

WebSocket protocol (JSON):

- Subscribe: {"action":"subscribe","topic":"room:global"}
- Unsubscribe: {"action":"unsubscribe","topic":"room:global"}
- Publish (client->server): {"action":"publish","topic":"room:global","payload":{...}}

Broadcast messages (server->client) are JSON with fields: `event_type`, `payload`, `timestamp`.

Example DB trigger that emits NOTIFY with JSON payload: `examples/pg_trigger.sql`.

