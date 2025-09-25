@echo off

docker-compose run --rm alpine-set-exe sh -c "find /mnt/wmui -name "*.sh" -exec chmod +x {} \;"

echo Finished!

pause
