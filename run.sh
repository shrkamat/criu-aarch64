#/bin/bash

docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t criu_builder .
docker run -it --rm -v $PWD/criu:/opt/criu -v$PWD/output:/output criu_builder
