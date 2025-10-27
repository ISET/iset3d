#/bin/sh
#
ARCH=`arch`
ARCH=linux/arm64/v8
TAG=arm
docker buildx build --platform=$ARCH -f Dockerfile_cpu --tag vistalab/pbrt-v4-cpu:$TAG  `pwd`
#docker push vistalab/pbrt-v4-cpu:$TAG


