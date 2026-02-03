SET WMUI_TEST_Templates=msr/1101/sel-25924
SET WMUI_TEST_USE_LATEST_PRODUCTS_LIST=true
docker compose run --rm wmui-zip-img-builder
docker compose down -t 0 -v
