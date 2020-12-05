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
