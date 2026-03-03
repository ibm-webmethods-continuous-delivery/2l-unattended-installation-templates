SET WMUI_TEST_Templates=em/1101/full designer/1101/esb-01 dbc/1101/full msr/1101/simple agw/1101/cds-e2e msr/1101/sel-25924
SET WMUI_TEST_UNION_ZIPS_ONLY=true
docker compose run --rm wmui-zip-img-builder
docker compose down -t 0 -v
