alter session set "_ORACLE_SCRIPT"=true;
create user webmethods identified by Password02;
grant all privileges to webmethods;
create user wmarchive identified by Password03;
grant all privileges to wmarchive;
-- TODO: parametrize to take these from env vars
--       until then, make sure they match !

-- Made with Bob
