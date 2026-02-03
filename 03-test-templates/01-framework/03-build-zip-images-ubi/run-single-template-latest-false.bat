SET WMUI_TEST_Templates=dbc/1101/full
SET WMUI_TEST_USE_LATEST_PRODUCTS_LIST=false
docker compose run --rm wmui-zip-img-builder
docker compose down -t 0 -v
