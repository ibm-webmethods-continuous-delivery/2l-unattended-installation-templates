# Local Build Test Harness for DBC Container Image

This is a test harness for the container build template `05.container-image-builders/DBC/1101/full/alpine` that relies on the template `DBC/1101/full`.

## Windows (e.g. with Rancher Desktop)

- Procure the product and fix images first. See the [root README-s quickstart](../../../../README.md#quick-start) instructions
- Copy `Example.setEnv.bat` into `setEnv.bat`
- Edit `setEnv.bat` to point to the files you downloaded
- run `runTestLocal.bat`
