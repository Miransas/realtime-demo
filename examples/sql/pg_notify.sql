-- Create a notifications table and trigger function that NOTIFYs JSON payload to 'realtime_channels'

CREATE TABLE IF NOT EXISTS notifications (
  id serial primary key,
  table_name text not null,
  action text not null,
  payload jsonb,
  created_at timestamptz default now()
);

CREATE OR REPLACE FUNCTION notify_realtime() RETURNS trigger AS $$
DECLARE
  data jsonb;
  action_text text;
BEGIN
  IF TG_OP = 'INSERT' THEN
    action_text := 'insert';
    data := row_to_json(NEW)::jsonb;
  ELSIF TG_OP = 'UPDATE' THEN
    action_text := 'update';
    data := row_to_json(NEW)::jsonb;
  ELSIF TG_OP = 'DELETE' THEN
    action_text := 'delete';
    data := row_to_json(OLD)::jsonb;
  END IF;

  PERFORM pg_notify('realtime_channels', json_build_object(
    'action', action_text,
    'table', TG_TABLE_NAME,
    'topic', 'table:' || TG_TABLE_NAME,
    'payload', data
  )::text);

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Example: attach to 'messages' table
-- DROP TRIGGER IF EXISTS messages_notify ON messages;
-- CREATE TRIGGER messages_notify
-- AFTER INSERT OR UPDATE OR DELETE ON messages
-- FOR EACH ROW EXECUTE FUNCTION notify_realtime();
