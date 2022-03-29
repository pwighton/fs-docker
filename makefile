FS_LICENSE_BASE64 ?= ""
FS_REPO ?= "https://github.com/freesurfer/freesurfer"
FS_BRANCH ?= "dev"
ND ?= "neurodocker"

#all: fs-build
#all: fs-build fs-run

fs-build:
	cd ./build && docker build -t pwighton/fs-dev-build .

fs-build-nc:
	cd ./build && docker build --no-cache -t pwighton/fs-dev-build .

fs-run:
	cd ./run && docker build -t pwighton/fs-dev-run .

fs-run-nc:
	cd ./run && docker build --no-cache -t pwighton/fs-dev-run .

fs-720:
	${ND} generate docker \
	    --base-image ubuntu:xenial \
	    --pkg-manager apt \
	    --freesurfer version=7.2.0 \
	    --matlabmcr version=2014b install_path=/opt/MCRv84 \
	    --run "ln -s /opt/MCRv84/v84 /opt/freesurfer-7.2.0/MCRv84" \
	    | docker build -t pwighton/freesurfer:7.2.0 -

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
	      repo=https://github.com/pwighton/freesurfer.git \
	      branch=20220224-gems-cmake-rework \
	      license_base64=${FS_LICENSE_BASE64} \
	      infant_module=ON \
	      dev_tools=ON \
	    --entrypoint '/bin/infant-container-entrypoint-aws.bash' \
	| docker build -t pwighton/fs-infant-dev -

# Same as above, but the h5 skullstripped files are copied into the container
fs-infant-dev-model-inside:
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
	      repo=https://github.com/pwighton/freesurfer.git \
	      branch=20220224-gems-cmake-rework \
	      license_base64=${FS_LICENSE_BASE64} \
	      infant_module=ON \
	      dev_tools=ON \
	      infant_model_s3=s3://freesurfer-annex/infant/model/dev/ \
	      infant_model_s3_region=us-east-2 \
	    --entrypoint '/bin/infant-container-entrypoint-aws.bash' \
	| docker build -t pwighton/fs-infant-dev -
	
# alt:
# --entrypoint '/bin/infant-container-entrypoint-aws.bash' \

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
	      version=usa-nh \
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

petsurfer:
	${ND} generate docker \
	    --yes \
	    --base-image python:3.8-buster \
	    --pkg-manager apt \
	    --fsl \
	      version=5.0.10 \
	      method=binaries \
	    --freesurfer \
	      version=7.2.0 \
	    | docker build -t pwighton/petsurfer:7.2.0 -

petsurfer-bids:
	cd ./petsurfer-bids && docker build -f dockerfile --no-cache -t pwighton/petsurfer-bids:7.2.0 .

petsurfer-bids-vb:
	cd ./petsurfer-bids && docker build -f dockerfile-vb-test --no-cache -t pwighton/petsurfer-bids-vb:7.2.0 .

fs-pet-dev-nipype-base:
	${ND} generate docker \
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
	    license_base64=${FS_LICENSE_BASE64} \
	    dev_tools=ON \
	    minimal=OFF \
	    samseg_atlas_build=OFF \
	    infant_module=OFF \
	  --fsl \
	    version=5.0.10 \
	    method=binaries \
	| docker build --no-cache -t pwighton/petsurfer-bids-base:dev -

fs-pet-dev-nipype:
	cd ./petsurfer-bids && docker build -f dockerfile-dev --no-cache -t pwighton/petsurfer-bids:dev .
