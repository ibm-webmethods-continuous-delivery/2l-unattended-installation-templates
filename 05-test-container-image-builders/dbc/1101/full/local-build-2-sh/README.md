# Local Build Test Harness for DBC Container Image without local WMUI

This is a test harness for the container build template `04-container-image-builders/dbc/1101/full/alpine` that relies on the template `dbc/1101/full`.

This second test is looking at running the local-install.sh script that is downloaded on-the fly. I.e. The user only needs to have the binary files prepared in advance, but no WMUI tooling.

## Linux (e.g. with Docker or Rancher Desktop)

- Procure the product and fix images first. See the [root README-s quickstart](../../../../../README.md#quick-start) instructions
- Copy `example.set-env.sh` into `set-env.sh`
- Edit `set-env.sh` to point to the files you downloaded
- run `./run-test-local.sh`
