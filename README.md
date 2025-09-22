# IBM webMethods Unattended Installation Assets

- [IBM webMethods Unattended Installation Assets](#ibm-webmethods-unattended-installation-assets)
  - [Quick Start](#quick-start)
  - [Folders](#folders)
    - [01.scripts](#01scripts)
    - [02.templates](#02templates)
      - [02.templates.01.setup](#02templates01setup)
      - [02.templates.02.post-setup](#02templates02post-setup)
    - [03.test](#03test)
    - [09.utils](#09utils)
  - [Important notes](#important-notes)
  - [Acknowledgements](#acknowledgements)

Collection of scripts to be "curled" during unattended cloud installations for IBM webMethods products.

## Quick Start

After cloning, the user may immediately obtain the installation and patching binary files by using the test harness `03.test\framework\assureBinaries\alpine`.

## Folders

### 01.scripts

Contain the scripting assets for this repository. This is the core of the overall project.

### 02.templates

Contains templates for installations which leverage the core functions in the scripting assets. These are further divided in

#### 02.templates.01.setup

#### 02.templates.02.post-setup

### 03.test

Contain test harnesses for the scripts and templates

### 09.utils

Utilities supporting the considered use cases, e.g. a kernel properties setter for Elasticsearch.

## Important notes

- All files must have unix style end lines even when using docker desktop for Windows. Clone accordingly!

## Acknowledgements

This repository is using some other libraries under the hood. These are not copied directly, but may be downloaded on demand at runtime.

These libraries include:

- [shunit2](https://github.com/kward/shunit2) - Apache 2 license [here](https://github.com/kward/shunit2/blob/master/LICENSE)

------------------------------

These tools are provided as-is and without warranty or support. They do not constitute part of the webMethods product suite. Users are free to use, fork and modify them, subject to the license agreement. While we welcome contributions, we cannot guarantee to include every contribution in the master project.

