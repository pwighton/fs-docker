# fs-docker

Notes on how containers can support:
- Running Released Versions of FreeSurfer
- Running FreeView
- Compiling FreeSurfer (e.g. `HEAD` of `dev` branch)
- Running Compiled Versions of FreeSurfer

## Containers For Released Versions of FreeSurfer
The container `freesurfer/freesurfer` was built using the [dockerfile in the FreeSurfer repo](https://github.com/freesurfer/freesurfer/blob/dev/Dockerfile)

e.g. from the FreeSurfer source directory
```
docker build -t freesurfer/freesurfer:dev
```

You can also build containers with previous release versions of FreeSurfer using [NeuroDocker](https://github.com/ReproNim/neurodocker).

e.g.
```
docker run repronim/neurodocker generate docker \
  --base continuumio/miniconda:4.7.12 \
  --pkg-manager apt \
  --freesurfer version=7.1.1 \
    | docker build -t pwighton/freesurfer:7.1.1 -
```

Neurodocker is a convenient way to build containers if additional software is required.  For example, to install the Matlab compiler runtime to support the SAMSEG stream:
```
docker run repronim/neurodocker generate docker \
  --base continuumio/miniconda:4.7.12 \
  --pkg-manager apt \
  --freesurfer version=7.1.1 \
  --matlabmcr version=2014b install_path=/opt/MCRv84 \
  --run "ln -s /opt/MCRv84/v84 /opt/freesurfer-7.1.1/MCRv84" \
    | docker build -t pwighton/freesurfer-mcr:7.1.1 -
```

The container [`pwighton/freesurfer:7.1.1-min`](https://hub.docker.com/layers/128181705/pwighton/freesurfer/7.1.1-min/images/sha256-d6b94ae6ff7a2490ded07bacba1eacd04d02f259cdfb94167dcccdaaf02c446d?context=explore) is a minimized version (359.8 MB compressed) of `pwighton/freesurfer:7.1.1` that supports both the cross and long streams of [recon-all](`pwighton/freesurfer:7.1.1`).  See [`notes/20201127-fs711-neurodocker-min.md`](notes/20201127-fs711-neurodocker-min.md) for details on how this container was created using neurodocker.

### License Management

The containers above require a valid FreeSurfer license, which is not included in the container.  You can request a license for free [here](https://surfer.nmr.mgh.harvard.edu/registration.html), which will email you a file called `license.txt`.  There are two ways to get that license file inside the container:

#### 1) Bind mount the license.txt file and set an environment variable

We can bind mount the license file (`docker run -v`) into the container, and then set the environment variable `FS_LICENSE` to tell FreeSurfer where to look for the license file.

e.g Assuming the file is saved on your computer at `~/license.txt`
```
docker run -it --rm \ 
  -v ~/license.txt:/license.txt:ro \
  -e FS_LICENSE='/license.txt' \
  freesurfer/freesurfer:7.2.0 \
    recon-all -all -s bert
```

#### 2) Create a derived container with the license file

e.g. make a `dockerfile` like
```
FROM freesurfer/freesurfer:7.1.1
COPY license /usr/local/freesurfer/.license
```
Then run `docker build`

## Containers for FreeView

The best way to run FreeView in a container is via [neurodesk](https://neurodesk.github.io/)

Quickstart:
```
mkdir -p ~/neurodesktop-storage
sudo docker run \
  --shm-size=1gb -it --privileged --name neurodesktop \
  -v ~/neurodesktop-storage:/neurodesktop-storage \
  -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  -p 8080:8080 -h neurodesktop-20211028 \
  vnmd/neurodesktop:20211028
```

Then visit http://localhost:8080/#/?username=user&password=password and install FreeSurfer and Launch FreeView via the GUI

## Containers for Compiling FreeSurfer

This [branch of neurodocker](https://github.com/pwighton/neurodocker/tree/20210825-refactor) can compile FreeSurfer from source.  The corresponding container for this branch of neurodocker is `pwighton/neurodocker`

e.g
```
docker run pwighton/neurodocker \
  generate docker \
    --base-image ubuntu:xenial \
    --pkg-manager apt \
    --yes \
    --freesurfer \
      method=source \
      repo=https://github.com/freesurfer/freesurfer.git \
      license_base64=$FS_LICENSE \
      version=dev \
      minimal=off \
      dev_tools=on \
| docker build --no-cache -t pwighton/fs-dev-monolith-example -
```

There are several options that can be passed to freesurfer when installed from source.  This is under active development and may change:

- You can pass the license file as a base64 encoded string (`cat ./license.txt |base64 -w0`) at container build time via `license_base64`
- setting `dev_tools` to `on` keeps the freesurfer source directory in the container under `/stage` it also installs jupyter notebook inside the container and awscli.
- setting `minimal` to `on` will only compile the binaries required to run `recon-all`
- setting `infant_module` to `on` will compile infant-specific binaries and install required python packages
- setting `samseg_atlas_build` to `on` with configure the container to build samseg atlases, everything else will likely break (WIP)

## Common use cases

### `docker build` use cases

#### Build a monolithic container for FreeSurfer Development

```
docker run pwighton/neurodocker:latest generate docker \
  --base-image ubuntu:xenial \
  --pkg-manager apt \
  --yes \
  --freesurfer \
    method=source \
    license_base64=replace_this_string_with_the_output_of_cat_./license.txt_|base64_-w0 \ 
    repo=https://github.com/pwighton/freesurfer.git \
    version=20210813-gems \
    minimal=off \
    samseg_atlas_build=off \
    infant_module=off \
    dev_tools=on \
| docker build --no-cache -t pwighton/fs-dev-monolith -
```

This will:
  - Compile the branch `20210813-gems` of the `pwighton/freesurfer` fork
  - Base64 decode the contents of the `license_base64` and save it to `license_path`/`license_file`, which can also be specified (defaults to `/opt/license.txt`) 
  - Install development tools which:
    - Keeps the freesurfer source directory under `/stage`
    - Installs jupyter notebook
    - Install `awscli`

#### Build a container for infant pipeline dev/test
```  
docker run pwighton/neurodocker:latest generate docker \
  --base-image ubuntu:xenial \
  --pkg-manager apt \
  --yes \
  --niftyreg \
    version=master \
  --fsl \
    version=5.0.10 \
    method=binaries \
  --freesurfer \
    method=source \
    repo=https://github.com/pwighton/freesurfer.git \
    branch=20210813-gems \
    license_base64=replace_this_string_with_the_output_of_cat_./license.txt_|base64_-w0 \ 
    infant_module=ON \
    dev_tools=ON \
  --entrypoint '/bin/infant-container-entrypoint-aws.bash' \
| docker build --no-cache -t pwighton/fs-infant-dev -
```

This will:
  - Install the prerequisites and python packages required to run the infant stream
  - Compile the branch `20210813-gems` of the `pwighton/freesurfer` fork
  - Base64 decode the contents of the `license_base64` and save it to `license_path`/`license_file`, which can also be specified (defaults to `/opt/license.txt`) 
  - Install development tools which:
    - Keeps the freesurfer source directory under `/stage`
    - Installs jupyter notebook
    - Install `awscli`

#### Build a container to run petsurfer

```
docker run pwighton/neurodocker:latest generate docker \
  --yes \
  --base-image python:3.8-buster \
  --pkg-manager apt \
  --fsl \
    version=5.0.10 \
    method=binaries \
  --freesurfer \
    version=7.2.0 \
| docker build -t pwighton/petsurfer:7.2.0 -
```

This will:
  - Install the prerequisites for petsurfer
  - Install a release version of freesurfer

#### Build a container to run the dev version of petsurfer

```
docker run pwighton/neurodocker:latest generate docker \
  --yes \
  --base-image ubuntu:xenial \
  --pkg-manager apt \
  --neurodebian \
    os_codename=xenial \
    version=usa-nh \
  --freesurfer \
    method=source \
    repo=https://github.com/freesurfer/freesurfer.git \
    branch=dev \
    license_base64=replace_this_string_with_the_output_of_cat_./license.txt_|base64_-w0 \ 
    dev_tools=ON \
    minimal=OFF \
    samseg_atlas_build=OFF \
    infant_module=OFF \
  --fsl \
    version=5.0.10 \
    method=binaries \
| docker build --no-cache -t pwighton/petsurfer-bids-base:dev -
```

This will:
  - Install the pre-requisites required to run petsurfer
  - Compile the branch `dev` branch of `freesurfer/freesurfer`
  - Base64 decode the contents of the `license_base64` and save it to `license_path`/`license_file`, which can also be specified (defaults to `/opt/license.txt`) 
  - Install development tools which:
    - Keeps the freesurfer source directory under `/stage`
    - Installs jupyter notebook
    - Install `awscli`
    
### `docker run` use cases

#### Interactive terminal

```
docker run -it --rm \
  -v ~/license.txt:/license.txt:ro \
  -e FS_LICENSE='/license.txt' \
  freesurfer/freesurfer:7.2.0 \
    /bin/bash
```

This will
  - Mount the freesurfer license file at `~/license.txt` to `/license.txt` inside the container
  - Set the environment variable `FS_LICENSE` to `/license.txt`
  - Return a bash prompt
  
#### A Jupyter notebook withing a FreeSurfer dev env

```
docker run -it --rm \
  -p 8888:8888 \
  -v ${HOME}/my_notebook_dir:${HOME}/my_notebook_dir \
  -w ${HOME}/my_notebook_dir \
    pwighton/fs-dev-monolith:aa8f76b \
      jupyter notebook --allow-root --no-browser --ip=0.0.0.0
```

This will:
  - Mount the directory `~/my_notebook_dir` into the container, at `~/my_notebook_dir`
  - Set the working directory to `~/my_notebook_dir`
  - Start a jupyter notebook, which you can connect to via http://localhost:8888
    - See the terminal output for the token or full URL.
  - With FreeSurfer python bindings compiled and configured
    - e.g. try running `import FreeSurfer` in a notebook

#### Run petsurfer on a bids dataset

The file [`petsurfer-bids/dockefile`](petsurfer-bids/dockerfile) inherits from `pwighton/petsurfer:7.2.0` and installs the following two repositories
- The `add_pet_freesurfer` branch of https://github.com/mnoergaard/nipype.git
  - nipype interfaces for petsurfer
- The `main` branch of https://github.com/openneuropet/petpipeline.git
  - A nipype workflow to execute petsurfer on PET-BIDS datasets

Building this gives the container `pwighton/petsurfer-bids`, which can be used to run on PET-BIDS datasets and invoked as follows:

Setup; download a PET-BIDS dataset from openneuro.  For this example I'm using [`ds001421`](https://openneuro.org/datasets/ds001421/versions/1.2.1):
```
mkdir /home/paul/lcn/20211019-petpipeline-test
cd /home/paul/lcn/20211019-petpipeline-test
aws s3 sync s3://openneuro.org/ds001421 ./ds001421
```

Run:
```
docker run -it --rm \
  -v /home/paul/lcn/20211019-petpipeline-test:/home/paul/lcn/20211019-petpipeline-test \
  -v ${HOME}/license.txt:/license.txt:ro \
  -e FS_LICENSE='/license.txt' \
  pwighton/petsurfer-bids:7.2.0 \
    /opt/petpipeline/petpipeline/main.py \
      -c /opt/petpipeline/petpipeline/config.yaml \
      -e /home/paul/lcn/20211019-petpipeline-test \
      -o output \
      -w temp \
      -d /home/paul/lcn/20211019-petpipeline-test/ds001421
```



