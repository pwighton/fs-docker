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
	      conda_install="python=3.6.5 numpy==1.16.* scipy" \
	      pip_install="nibabel six pyyaml scikit-image tables keras==2.3.* tensorflow==2.4.* sklearn" \
	      activate=true \
	> baby/dockerfile.fs-baby-base

fs-baby-base: fs-baby-base-dockerfile
	cd ./baby && docker build -t pwighton/fs-baby-base -f dockerfile.fs-baby-base .
	
fs-baby-base-nc: fs-baby-base-dockerfile
	cd ./baby && docker build --no-cache -t pwighton/fs-baby-base -f dockerfile.fs-baby-base .