-- Initialize database: create items table and trigger to notify realtime_events channel

CREATE TABLE IF NOT EXISTS items (
  id serial primary key,
  data jsonb not null,
  inserted_at timestamptz default now(),
  updated_at timestamptz default now()
);

CREATE OR REPLACE FUNCTION notify_realtime_events() RETURNS trigger AS $$
DECLARE
  payload jsonb;
  action_text text;
BEGIN
  IF TG_OP = 'INSERT' THEN
    action_text := 'insert';
    payload := row_to_json(NEW)::jsonb;
  ELSIF TG_OP = 'UPDATE' THEN
    action_text := 'update';
    payload := row_to_json(NEW)::jsonb;
  ELSIF TG_OP = 'DELETE' THEN
    action_text := 'delete';
    payload := row_to_json(OLD)::jsonb;
  END IF;

  PERFORM pg_notify('realtime_events', json_build_object(
    'action', action_text,
    'table', TG_TABLE_NAME,
    'topic', 'room:global',
    'payload', payload
  )::text);

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to items table
DROP TRIGGER IF EXISTS items_notify ON items;
CREATE TRIGGER items_notify
  AFTER INSERT OR UPDATE OR DELETE ON items
  FOR EACH ROW EXECUTE FUNCTION notify_realtime_events();
