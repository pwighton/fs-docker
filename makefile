FS_LICENSE_BASE64 ?= ""
FS_REPO ?= "https://github.com/freesurfer/freesurfer"
FS_BRANCH ?= "dev"
ND ?= "neuroocker"

all: fs-build
#all: fs-build fs-run

fs-build:
	cd ./build && docker build -t pwighton/fs-dev-build .

fs-build-nc:
	cd ./build && docker build --no-cache -t pwighton/fs-dev-build .

fs-run:
	cd ./run && docker build -t pwighton/fs-dev-run .

fs-run-nc:
	cd ./run && docker build --no-cache -t pwighton/fs-dev-run .

# via neurodocker (WIP) https://github.com/pwighton/neurodocker/tree/20210226-fs-source

# todo 2021/09/07: replace entrypoint filepath with equivalent ${FREESURFER_HOME} (`/opt/freesurfer-*`) 
# path after entrypoint gets installed
fs-infant-dev:
	${ND} generate docker \
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
	      version=20210813-gems \
	      license_base64=${FS_LICENSE_BASE64} \
	      repo=https://github.com/pwighton/freesurfer.git \
	      infant_module=ON \
	      dev_tools=ON \
	    --entrypoint '/bin/infant-container-entrypoint-aws.bash' \
	| docker build -t pwighton/fs-infant-dev -

fs-baby: fs-baby-base
	cd ./baby && docker build -t pwighton/fs-baby .

fs-baby-nc: fs-baby-base-nc
	cd ./baby && docker build --no-cache -t pwighton/fs-baby .

# Notes:
# 1) FreeSurfer python reqs
#   - https://github.com/freesurfer/freesurfer/blob/dev/python/requirements.txt
# 2) Python version should match version in `build/Dockerfile` for python bindings to work
fs-baby-base-dockerfile:
	docker run repronim/neurodocker \
	  generate docker \
	    --base ubuntu:xenial \
	    --pkg-manager apt \
	    --neurodebian \
	      os_codename=xenial \
	      server=usa-nh \
	    --fsl \
	      version=5.0.10 \
	      method=binaries \
	    --miniconda \
	      create_env=freesurfer \
	      conda_install="python=3.6.6" \
	      activate=true \
	> baby/dockerfile.fs-baby-base
	
fs-baby-base: fs-baby-base-dockerfile
	cd ./baby && docker build -t pwighton/fs-baby-base -f dockerfile.fs-baby-base .
	
fs-baby-base-nc: fs-baby-base-dockerfile
	cd ./baby && docker build --no-cache -t pwighton/fs-baby-base -f dockerfile.fs-baby-base .
