# zmt-bot
app to recommend track based on user audio profile

## Build image
https://docs.docker.com/build/building/multi-platform/#qemu
```shell
docker run --privileged --rm tonistiigi/binfmt --install all
docker run --privileged --rm multiarch/qemu-user-static --reset -p yes
docker buildx create --driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=-1 --driver-opt env.BUILDKIT_STEP_LOG_MAX_SPEED=-1 --name multiarch --driver docker-container --bootstrap
docker buildx use multiarch
```
Run build on amd64:
```shell
export REPRO_VERSION=1.0.0
docker buildx bake --progress=plain 2>&1 | tee bake.log
```
> `Dockerfile`s can contain lots of not needed stuff - the repro is sourced from more complex project with more dependencies

Then you can save image to tar to import on the device
```shell
docker save "repro:${REPRO_VERSION}-armv7-32k" > "repro_${REPRO_VERSION}-armv7-32k".tar
```