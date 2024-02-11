# Template build script for creating a Docker image with pbrt-v4-gpu
# Needs to be edited for specific Nvidia architecture
#
# make sure you have docker runtime set as nvidia-runtime
# docker build --no-cache --tag camerasimulation/pbrt-v4-gpu `pwd`
docker build -f Dockerfile_volta --tag digitalprodev/pbrt-v4-gpu-volta-mux `pwd`

# if you have permission to push, and know what you are doing...
docker push digitalprodev/pbrt-v4-gpu-volta-mux:latest

