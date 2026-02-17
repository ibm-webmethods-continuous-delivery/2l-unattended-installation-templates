#!/bin/sh

## Enforce as needed, this is the happy path

### First database

echo "Initializing the main database ${EX99_WM_DB_NAME}"

__l_db_url="jdbc:wm:postgresql://db:5432;databaseName=${EX99_WM_DB_NAME}"

"${EX99_DBC_WM_HOME}"/common/db/bin/dbConfigurator.sh \
--action create \
--dbms pgsql \
--component all \
--version latest \
--url "${__l_db_url}" \
--printActions \
--user "${EX99_WM_DB_USER_NAME}" \
--password "${EX99_WM_DB_USER_PASS}"

echo "Initializing the archive database ${EX99_WM_ARCHIVE_DB_NAME}"

__l_db_url="jdbc:wm:postgresql://db:5432;databaseName=${EX99_WM_ARCHIVE_DB_NAME}"
__l_arc_components="ActiveTransferArchive,Archive,ComponentTracker,DataPurge,TaskArchive,TradingNetworksArchive"

"${EX99_DBC_WM_HOME}"/common/db/bin/dbConfigurator.sh \
--action create \
--dbms pgsql \
--component ${__l_arc_components} \
--version latest \
--url "${__l_db_url}" \
--printActions \
--user "${EX99_WM_ARCHIVE_DB_USER_NAME}" \
--password "${EX99_WM_ARCHIVE_DB_USER_PASS}"
