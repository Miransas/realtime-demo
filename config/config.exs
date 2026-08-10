import Config

config :realtime_engine, port: System.get_env("PORT") && String.to_integer(System.get_env("PORT")) || 4000

config :realtime_engine, :postgres,
  hostname: System.get_env("PG_HOST") || "localhost",
  username: System.get_env("PG_USER") || "postgres",
  password: System.get_env("PG_PASS") || "",
  database: System.get_env("PG_DB") || "postgres",
  port: System.get_env("PG_PORT") && String.to_integer(System.get_env("PG_PORT")) || 5432

config :realtime_engine, :pg_channel, System.get_env("PG_CHANNEL") || "realtime_channels"
import Config

config :realtime, port: System.get_env("PORT") && String.to_integer(System.get_env("PORT")) || 4000

# Postgrex connection options, can be provided via ENV in prod
config :realtime, :postgres,
  hostname: System.get_env("PG_HOST") || "localhost",
  username: System.get_env("PG_USER") || "postgres",
  password: System.get_env("PG_PASS") || "",
  database: System.get_env("PG_DB") || "postgres",
  port: System.get_env("PG_PORT") && String.to_integer(System.get_env("PG_PORT")) || 5432

config :realtime, :pg_channel, System.get_env("PG_CHANNEL") || "realtime:changes"
