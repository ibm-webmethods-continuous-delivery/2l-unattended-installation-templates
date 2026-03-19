# Oracle Database Initialization Scripts

These SQL scripts are automatically executed by the Oracle container during startup.

## Files

- `create_tablespaces.sql` - Creates tablespaces for webMethods components
- `create_users.sql` - Creates database users (webmethods, wmarchive)

## Note

The scripts are mounted to `/opt/oracle/scripts/startup` in the Oracle container and executed automatically during database initialization.

Passwords are currently hardcoded in `create_users.sql` and must match the values in the `.env` file.