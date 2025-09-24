docker compose -f docker-compose-init.yml run --rm db-init

docker compose -f docker-compose-init.yml down -t 60
