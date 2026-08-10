import Config

config :realtime_engine, port: System.get_env("PORT") && String.to_integer(System.get_env("PORT")) || 4000

# Postgrex connection options, can be provided via ENV in prod
config :realtime_engine, :postgres,
  hostname: System.get_env("PG_HOST") || "localhost",
  username: System.get_env("PG_USER") || "postgres",
  password: System.get_env("PG_PASS") || "postgres",
  database: System.get_env("PG_DB") || "realtime_db",
  port: System.get_env("PG_PORT") && String.to_integer(System.get_env("PG_PORT")) || 5432

config :realtime_engine, :pg_channel, System.get_env("PG_CHANNEL") || "realtime_events"
