#docker build --no-cache --tag camerasimulation/pbrt-v4-cpu `pwd`
docker build -f Dockerfile_cpu --tag digitalprodev/pbrt-v4-cpu `pwd`
docker push digitalprodev/pbrt-v4-cpu:latest


