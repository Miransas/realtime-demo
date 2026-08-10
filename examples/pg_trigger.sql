-- Example SQL to create trigger which sends NOTIFY with JSON payload
-- Adjust table name and payload as needed.

CREATE OR REPLACE FUNCTION notify_table_change() RETURNS trigger AS $$
DECLARE
  payload json;
  action_text text;
BEGIN
  IF (TG_OP = 'INSERT') THEN
    action_text := 'insert';
    payload := row_to_json(NEW);
  ELSIF (TG_OP = 'UPDATE') THEN
    action_text := 'update';
    payload := row_to_json(NEW);
  ELSIF (TG_OP = 'DELETE') THEN
    action_text := 'delete';
    payload := row_to_json(OLD);
  END IF;

  PERFORM pg_notify('realtime:changes', json_build_object(
    'action', action_text,
    'table', TG_TABLE_NAME,
    'topic', 'table:' || TG_TABLE_NAME,
    'payload', payload
  )::text);

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Example for table 'messages'
DROP TRIGGER IF EXISTS messages_notify_trigger ON messages;
CREATE TRIGGER messages_notify_trigger
  AFTER INSERT OR UPDATE OR DELETE ON messages
  FOR EACH ROW EXECUTE PROCEDURE notify_table_change();
