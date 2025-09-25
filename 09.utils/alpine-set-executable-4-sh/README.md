# Set executable shells

This little project is setting all the shell scripts in this repo to be executable.

This is needed sometimes immediately after cloning the repo, for example on Windows WSL based systems, because usually cross OS repos are not maintaining UNIX file properties.

On a docker compose capable system just run the command 

```sh
docker-compose run --rm alpine-set-exe sh -c "find /mnt/wmui -name "*.sh" -exec chmod +x {} \;"
```

This command is also written in the file `run.bat` .
