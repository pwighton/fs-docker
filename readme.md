# fs-docker

[Building FS7 docker containers with neurodocker](20200507-fs7-neurodocker.md)

Dockerfiles to support:
- developing FreeSurfer (compiling FreeSurfer from source)
- running development versions of FreeSurfer (using locally compiled FreeSurfer binaries)
- running prepackaged versions of FreeSurfer (using pre-built development versions, or released packages of FreeSurfer)


## *NOTE:* Currently a Work In Progress, everything below here is subject to change
### The `freesurfer-build` container
-----------------------------------------------------------------------

The `freesufer-build` container is used to build the dev branch of FreeSurfer and is based on Ubuntu 16.04.3 LTS (Xenial Xerus).  It is built from the file `build/Dockerfile`

#### Pre-reqs
- Install docker
- Install git
- Install git-annex

#### Setup
Outside the container, we want to make a directory structure that looks like:
```
└── fs-development
    ├── bin
    ├── freesurfer
    ├── fs-docker
    └── packages
```

Where:
  - `./fs-development/bin/` is where the compiled FreeSurfer binaries will be installed with `make install`
  - `./fs-development/freesurfer` is the [FreeSurfer repo](https://github.com/freesurfer/freesurfer)
  - `./fs/packages` is the required pre-compiled depedencies
  - `./fs-development/fs-docker` is this repo.

The `fs-development` directory will get mounted to `/fs` inside the container when it is executed.

```
mkdir -p ~/fs-development/bin
cd ~/fs-development
wget http://surfer.nmr.mgh.harvard.edu/pub/data/fspackages/prebuilt/centos7-packages.tar.gz
tar zxvf centos7-packages.tar.gz
git clone https://github.com/freesurfer/freesurfer.git ./freesurfer
cd ./freesurfer
git checkout dev
```

You can compile FreeSurfer now, but if you want to install/run it, some additional files are needed:
```
git remote add datasrc https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/repo/annex.git
git fetch datasrc
git annex enableremote datasrc
git annex get --metadata fstags=makecheck . && git annex get --metadata fstags=makeinstall .
```

If the annex tags haven't been updated, you might need to run
```
git annex get .
```

#### Build/Tag Containers
```
make fs-build
```

#### Compile FreeSurfer dev branch inside container:

#### Go interactive 
Mount the `fs-development` directory to `/fs` inside the container; make `/fs` the working directory and preserve UID/GID
```
cd ~
docker run -it --rm \
  -v ${PWD}/fs-development:/fs \
  -w /fs \
  -u ${UID}:${GID} \
  corticometrics/freesurfer-build:latest \
  /bin/bash
```

You should now have an interactive terminal inside the container.

#### Compile FreeSurfer

From inside the container, run:

```
cd ./freesurfer
rm -f CMakeCache.txt
cmake -DFS_PACKAGES_DIR="/fs/packages" -DBUILD_GUIS=OFF .
make -j 4
```

#### Install
If you've run `git annex get --metadata fstags=makeinstall .` above, you should be able to:
```
make install
```
This should install FreeSurfer to `/fs/bin` (inside the container)

Now, type `exit` to exit the container.  Since `~/fs-development/bin` was mounted inside the container to `/fs/bin`, you should now have a full FreeSurfer install dir at `~/fs-development/bin`

### The `freesurfer-run` container
-----------------------------------------------------------------------

The `freesurfer-run` container is used to run dev branch version of `recon-all` and is based on Ubuntu 16.04.3 LTS (Xenial Xerus).  It is built from the file `run/Dockerfile`

#### Pre-reqs
- Install docker
- Obtain FreeSurfer binaries (either by following the steps above to compile or [download](https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall))
- Obtain FreeSurfer subject data to recon
- Obtain FreeSurfer license (from [here](https://surfer.nmr.mgh.harvard.edu/registration.html)) 

#### Setup

##### Build/Tag Container
```
make fs-run
```

##### Get `FS_KEY` value

The [entrypoint script](run/entrypoint.freesurfer-run.bash) for this container looks for the environment variable `FS_KEY` and, if present, will base64-decode the string and store the contents in the file `$FREESURFER_HOME/license.txt`.  Most of FreeSurfer will not work without this license file.  

Obtaining a license file is free and can be applied for [here](https://surfer.nmr.mgh.harvard.edu/registration.html).  Once you have the license file, run `cat $FREESURFER_HOME/license.txt |base64 -w 0 && echo` to get the string that you should set the `FS_KEY` environment variable to.

#### Recon a subject

The `freesurfer-run` container expects: 
  - 2 volumes to be mounted.
    - The FreeSurfer install directory (`$FREESURFER_HOME`) should be mounted to `/freesurfer-bin` 
    - The FreeSurfer subjects directory (`$SUBJECTS_DIR`) should be mounted to `/subjects`
  - The `FS_KEY` environment variable is set to the base64-encoded string of the FreeSurfer license file

##### Example

Suppose:
  - The FreeSurfer install directory lives at `~/fs-development/bin`
  - The FreeSurfer subject directory lives at `/tmp/subjects/`
    - The FreeSurfer subject directory contains the subdirectory `bert`, which you would like to recon
  - The `FS_KEY` value is `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

Then, the following command will run recon-all on bert:
```
docker run -it --rm \
  -v ${HOME}/fs-development/bin:/freesurfer-bin \
  -v /tmp/subjects/:/subjects \
  -e FS_KEY='xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  -u ${UID}:${GID} \
  corticometrics/freesurfer-run:latest \
  recon-all -all -s bert
```
