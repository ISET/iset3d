# Template build script for creating a Docker image with pbrt-v4-gpu
# Needs to be edited for specific Nvidia architecture
#
# make sure you have docker runtime set as nvidia-runtime
# docker build --no-cache --tag camerasimulation/pbrt-v4-gpu `pwd`
TAG=`arch`
ARCH=linux/$TAG
docker buildx build --platform=$ARCH -f Dockerfile_ampere --tag vistalab/pbrt-v4-gpu:$TAG `pwd`


# if you have permission to push, and know what you are doing...
#docker push digitalprodev/pbrt-v4-gpu-ampere
#docker tag digitalprodev/pbrt-v4-gpu-ampere digitalprodev/pbrt-v4-gpu-ampere

