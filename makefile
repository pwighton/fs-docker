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

fs-baby:
	cd ./baby && docker build -t pwighton/fs-baby .

# docker run repronim/neurodocker \
#   generate docker \
#     --base ubuntu:xenial \
#     --pkg-manager apt \
#     --neurodebian \
#       os_codename=xenial \
#       server=usa-nh \
#     --miniconda \
#       create_env=freesurfer \
#       conda_install="numpy==1.16.* scipy" \
#       pip_install="nibabel six pyyaml scikit-image"\
#       activate=true \
#     --fsl \
#       version=5.0.10 \
#       method=binaries \
#  > baby/dockerfile.fs-baby-base
# ---
# FreeSurfer python reqs
#   - https://github.com/freesurfer/freesurfer/blob/dev/python/requirements.txt
fs-baby-base:
	docker run repronim/neurodocker generate docker --base ubuntu:xenial --pkg-manager apt --neurodebian os_codename=xenial server=usa-nh --miniconda create_env=freesurfer conda_install="numpy==1.16.* scipy" pip_install="nibabel six pyyaml scikit-image" activate=true --fsl version=5.0.10 method=binaries > baby/dockerfile.fs-baby-base
	cd ./baby && docker build -t pwighton/fs-baby-base -f dockerfile.fs-baby-base .
	



