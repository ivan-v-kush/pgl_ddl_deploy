-- Allow running regression suite with upgrade paths
\set v `echo ${FROMVERSION:-2.0}`
SET client_min_messages = warning;
CREATE TEMP TABLE v AS
SELECT :'v'::TEXT AS num;
DO $$
BEGIN

IF current_setting('server_version_num')::INT >= 100000
AND (SELECT num FROM v) != ALL('{1.0,1.1,1.2,1.3,1.4,1.5,1.6,1.7}'::text[]) THEN
RAISE LOG '%', 'USING NATIVE';

ELSE
CREATE EXTENSION pglogical;
END IF;

END$$;
DROP TABLE v;
CREATE EXTENSION pgl_ddl_deploy VERSION :'v';
CREATE FUNCTION set_driver() RETURNS VOID AS $BODY$
BEGIN

IF current_setting('server_version_num')::INT >= 100000 AND (SELECT extversion::numeric FROM pg_extension WHERE extname = 'pgl_ddl_deploy') >= 2.0 THEN
    ALTER TABLE pgl_ddl_deploy.set_configs ALTER COLUMN driver SET DEFAULT 'native'::pgl_ddl_deploy.driver;
    UPDATE pgl_ddl_deploy.set_configs SET driver = 'native'::pgl_ddl_deploy.driver;
END IF;

END;
$BODY$
LANGUAGE plpgsql;
SELECT set_driver();
