SET WMUI_TEST_Templates=dbc/1101/full msr/1101/simple
SET WMUI_TEST_UNION_ZIPS_ONLY=false
docker compose run --rm wmui-zip-img-builder
docker compose down -t 0 -v
