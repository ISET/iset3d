#/bin/sh
#
TAG=`arch`
ARCH=linux/$TAG
docker buildx build --platform=$ARCH -f Dockerfile_cpu --tag vistalab/pbrt-v4-cpu:$TAG  `pwd`
#docker push vistalab/pbrt-v4-cpu:$TAG


