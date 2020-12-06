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

fs-baby-base:
	docker run repronim/neurodocker generate docker --base ubuntu:xenial --pkg-manager apt --neurodebian os_codename=xenial server=usa-nh --fsl version=5.0.10 method=binaries --minc version=1.9.15 method=binaries > dockerfile.fs-baby-base
	docker run repronim/neurodocker generate docker --base ubuntu:xenial --pkg-manager apt --neurodebian os_codename=xenial server=usa-nh --fsl version=5.0.10 method=binaries --minc version=1.9.15 method=binaries | docker build -t pwighton/fs-baby-base -
