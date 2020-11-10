all: fs-build
#all: fs-build fs-run

fs-build:
	cd ./build && docker build -t pwighton/fs-dev-build .

#fs-run:
#	cd ./run && docker build -t pwighton/fs-dev-runrun .
