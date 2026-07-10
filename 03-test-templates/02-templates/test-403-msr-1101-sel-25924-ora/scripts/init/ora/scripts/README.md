# Oracle Database Initialization Scripts

These SQL scripts are automatically executed by the Oracle container during startup.

## Execution Order

Oracle executes scripts in `/opt/oracle/scripts/startup` in alphabetical order:

1. **create_tablespaces.sql** - Creates tablespaces for webMethods components
   - WEBMDATA, WEBMINDX, WEBMBLOB - Main database tablespaces
   - WEBMARCDATA, WEBMARCINDX, WEBMARCBLOB - Archive database tablespaces

2. **create_users.sql** - Creates database users
   - webmethods/Password02 - Main database user
   - wmarchive/Password03 - Archive database user

## Notes

- These scripts run before the DBC (Database Configurator) initialization
- User passwords are hardcoded and should match EXAMPLE.env
- TODO: Parametrize passwords using environment variables
- All users are granted full privileges for test purposes

## Made with Bob