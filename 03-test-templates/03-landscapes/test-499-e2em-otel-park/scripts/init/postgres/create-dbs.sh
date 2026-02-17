#!/bin/sh

_create_database_and_user(){
  # Parameters
  # $1 - database name
  # $2 - owner user name
  # $3 - user password

	echo "Creating database ${1} having owner ${2}"
	if ! psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" \
    -c "CREATE USER ${2} WITH PASSWORD '${3}';" \
    -c "CREATE DATABASE ${1};" \
    -c "ALTER DATABASE ${1} OWNER TO ${2};" ; then
    echo "error $? creating database ${1}"
    return 1
  else
    echo "successfully created database ${1}"
    return 0
  fi
}

_create_database_and_user "${EX99_WM_DB_NAME}" "${EX99_WM_DB_USER_NAME}" "${EX99_WM_DB_USER_PASS}"
_create_database_and_user "${EX99_WM_ARCHIVE_DB_NAME}" "${EX99_WM_ARCHIVE_DB_USER_NAME}" "${EX99_WM_ARCHIVE_DB_USER_PASS}"
