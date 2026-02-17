SET WMUI_TEST_Templates=dbc/1101/full msr/1101/sel-25924 agw/1101/cds-e2e
SET WMUI_TEST_UNION_ZIPS_ONLY=true
docker compose run --rm wmui-zip-img-builder
docker compose down -t 0 -v
