# fs-docker

Notes on how containers can support:
- Running Released Versions of FreeSurfer
- Running FreeView
- Compliling FreeSurfer (e.g. `HEAD` of `dev` branch)
- Running Compiled Versions of FreeSurfer

## Containers For Released Versions of FreeSurfer
-----------------------------------------------------------------------
The easiest way to generate a FreeSurfer dockerfiles is with [NeuroDocker](https://github.com/ReproNim/neurodocker).

For example, the container `pwighton/freesurfer:7.1.1` was generated using:

```
neurodocker generate docker \
  --base continuumio/miniconda:4.7.12 \
  --pkg-manager apt \
  --freesurfer version=7.1.1 \
  --matlabmcr version=2014b install_path=/opt/MCRv84 \
  --run "ln -s /opt/MCRv84/v84 /opt/freesurfer-7.1.1/MCRv84" \
    | docker build -t pwighton/freesurfer:7.1.1 -
```

The container [`pwighton/freesurfer:7.1.1-min`](https://hub.docker.com/layers/128181705/pwighton/freesurfer/7.1.1-min/images/sha256-d6b94ae6ff7a2490ded07bacba1eacd04d02f259cdfb94167dcccdaaf02c446d?context=explore) is a minimized version (359.8 MB compressed) of `pwighton/freesurfer:7.1.1` that supports both the cross and long streams of [recon-all](`pwighton/freesurfer:7.1.1`).

See [`notes/20201127-fs711-neurodocker-min.md`](notes/20201127-fs711-neurodocker-min.md) for details on how this container was created using neurodocker.

## Containers for FreeView
-----------------------------------------------------------------------
The best way to run FreeView in a container is via [vnm](https://github.com/NeuroDesk/vnm)

Quickstart:
```
mkdir -p ~/vnm
docker run --privileged \
  -e USER=neuro \
  -e PASSWORD=neuro \
  -v ~/vnm:/vnm \
  -v ~/data:/home/neuro/data \
  -p 6080:80 \
    vnmd/vnm:latest
```
Then visit http://localhost:6080/ and install FreeSurfer and Launch FreeView via the GUI

[`notes/20200513-fs7-freeview.md`](notes/20200513-fs7-freeview.md) has some (incomplete) notes on trying to get FreeView to work in a docker container.

## Containers for Compliling FreeSurfer
-----------------------------------------------------------------------
The `fs-dev-build` container  can be used to compile FreeSurfer from source.

Use `make fs-build` (or `make fs-build-nc` to build without using the cache) to build the container. Or pull: `docker pull pwighton/fs-dev-run`.

The [Dockerfile](build/Dockerfile) defines 3 volumes that must be mounted when the container is invoked:
- `VOLUME /fs-pkg`: The location of FreeSurfer's [pre-compiled binaries](http://surfer.nmr.mgh.harvard.edu/pub/data/fspackages/prebuilt/centos7-packages.tar.gz) (input to compilation)
- `VOLUME /fs-code`: The [source code for FreeSurfer](github.com/freesurfer/freesurfer) (input to compilation)
- `VOLUME /fs-bin`: The location of the FreeSurfer binaries (output of compilation)

### Example

Outside the container, we want to make a directory structure that looks like:
```
└── fs-dev
    ├── bin
    ├── freesurfer
    └── packages
```

#### Define Input/Output dirs
```
export FS_PKG=~/fs-dev/pkg
export FS_CODE=~/fs-dev/freesurfer
export FS_BIN=~/fs-dev/bin
```

#### Setup Dir structure

Get pre-compiled binaries and check out `dev` branch of freesurfer
```
mkdir -p ${FS_PKG}
mkdir -p ${FS_CODE}
mkdir -p ${FS_BIN}
wget -c http://surfer.nmr.mgh.harvard.edu/pub/data/fspackages/prebuilt/centos7-packages.tar.gz -O - | tar -xz -C ${FS_PKG} && mv ${FS_PKG}/packages/* ${FS_PKG} && rm -rf ${FS_PKG}/packages
git clone https://github.com/freesurfer/freesurfer.git ${FS_CODE} && cd ${FS_CODE} && git checkout dev
```

#### Download annex data (optional)

You can compile FreeSurfer now, but if you want to install/run it, some additional files are needed:
```
cd ${FS_CODE}
git remote add datasrc https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/repo/annex.git
git fetch datasrc
git annex enableremote datasrc
git annex get .
```

#### Launch container interactively

Mount all needed volumes and preserve UID/GID
```
docker run -it --rm \
  -v ${FS_BIN}:/fs-bin \
  -v ${FS_PKG}:/fs-pkg \
  -v ${FS_CODE}:/fs-code \
  -u ${UID}:${GID} \
  pwighton/fs-dev-build:latest \
    /bin/bash
```

You should now have an interactive terminal inside the container.

#### Compile FreeSurfer

From inside the container, run:
```
cmake \
 -DFS_PACKAGES_DIR="/fs-pkg" \
 -DCMAKE_INSTALL_PREFIX="/fs-bin" \
 -DBUILD_GUIS=OFF \
 -DMINIMAL=ON \
 -DGFORTRAN_LIBRARIES="/usr/lib/gcc/x86_64-linux-gnu/5/libgfortran.so" \
 -DINSTALL_PYTHON_DEPENDENCIES=OFF \
 -DDISTRIBUTE_FSPYTHON=OFF \
   .
```

Then 

```
make -j 4
```

#### Install
If you've run `git annex get .` above, you should be able to:
```
make install
```
This should install FreeSurfer to `/fs-bin` (inside the container)

Now, type `exit` to exit the container.  Since outside the container, the directory `${FS_BIN}` was was mounted inside the container to `/fs/bin` (`-v ${FS_BIN}:/fs-bin`), you should now have a full FreeSurfer install dir at `${FS_BIN}`

## Containers for Running FreeSurfer
-----------------------------------------------------------------------

The `fs-dev-run` container is used to run a specifc version of `recon-all` and is based on Ubuntu 16.04.3 LTS (Xenial Xerus).  It is built from the file `run/Dockerfile`

The container requires a free and easily available FreeSurfer [License](https://surfer.nmr.mgh.harvard.edu/registration.html). 

### Pre-reqs
- Install docker
- Obtain FreeSurfer binaries (either by following the steps above to compile or [download](https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall))
- Obtain FreeSurfer subject data to recon
- Obtain [FreeSurfer license](https://surfer.nmr.mgh.harvard.edu/registration.html)

#### Setup

Build/Tag Container
```
make fs-run
```

or pull:
```
docker pull pwighton/fs-dev-run
```

##### Managing the FreeSurfer License

There are two ways to pass the license to the container
- Via volume mount (`docker run -v`)
- Via environment varianle (`docker run -v FS_KEY='...'`)

To mount via volume, locate your license and mount in somewhere in the container:
```
  -v ${LICENSE_DIR}/license.txt:/data/license.txt
```

Set the environment variablle `FS_LICENSE` accordingly:
```
  -e FS_LICENSE='/data/license.txt'
```

The license file can also be passed direcly as a base64 encoded string.  This may result in the license being stored in logs.

Encode `license.txt`:
```
cat ./license.txt |base64 -w 999
```

Set the environment variablle `FS_KEY` accordingly:
```
  -e `FS_KEY='cGF1bEBjb3J0aWNvbWV0cmljcy---not-a-real-key---lrR3o2bnNYaGcKIEZTVXQweHY5UmlGcWMK'`
```

#### Passing in Binaries and Data

The `fs-dev-run` container expects: 
  - 2 volumes to be mounted.
    - The FreeSurfer install directory (`$FREESURFER_HOME`) should be mounted to `/freesurfer-bin` 
    - The FreeSurfer subjects directory (`$SUBJECTS_DIR`) should be mounted to `/subjects`

##### Example

Suppose:
  - The FreeSurfer install directory lives at `~/fs-development/bin`
  - The FreeSurfer subject directory lives at `/tmp/subjects/`
    - The FreeSurfer subject directory contains the subdirectory `bert`, which you would like to recon
  - The `FS_KEY` value is `cGF1bEBjb3J0aWNvbWV0cmljcy---not-a-real-key---lrR3o2bnNYaGcKIEZTVXQweHY5UmlGcWMK`
  - The FreeSurfer license file is located at `~/license.txt`

Then, either command command will run recon-all on bert:
```
docker run -it --rm \
  -v ${HOME}/fs-development/bin:/freesurfer-bin \
  -v /tmp/subjects/:/subjects \
  -e FS_KEY='cGF1bEBjb3J0aWNvbWV0cmljcy---not-a-real-key---lrR3o2bnNYaGcKIEZTVXQweHY5UmlGcWMK' \
  -u ${UID} \
  pwighton/fs-dev-run:latest \
    recon-all -all -s bert
```
or
```
docker run -it --rm \
  -v ${HOME}/fs-development/bin:/freesurfer-bin \
  -v /tmp/subjects/:/subjects \
  -v ${HOME}/license.txt:/data/license.txt
  -e FS_LICENSE='/data/license.txt'
  -u ${UID} \
  pwighton/fs-dev-run:latest \
    recon-all -all -s bert
```
