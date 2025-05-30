# syntax=docker/dockerfile-upstream:master
FROM ghcr.io/rust-cross/manylinux_2_28-cross:armv7 AS dependencies-builder
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV TARGET_ARCH=armv7-unknown-linux
ENV TARGET_ARCH_POSTFIX=gnueabihf
ENV CC_ENABLE_DEBUG_OUTPUT=1
ENV RUSTFLAGS="-g"

RUN getconf PAGE_SIZE
RUN apt update
RUN pip install pip setuptools maturin[patchelf] \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ARG CPU_COUNT=4
ENV CPU_COUNT=$CPU_COUNT

WORKDIR /polars
ARG JEMALLOC_SYS_WITH_LG_PAGE=15
ENV JEMALLOC_SYS_WITH_LG_PAGE=$JEMALLOC_SYS_WITH_LG_PAGE
ARG CARGO_BUILD_JOBS=4
ENV CARGO_BUILD_JOBS=$CARGO_BUILD_JOBS
ENV TARGET_POLARS_TAG=py-1.28.1

# RUN curl -L "https://launchpad.net/ubuntu/+source/mimalloc/2.0.5+ds-2/+build/23195677/+files/libmimalloc-dev_2.0.5+ds-2_armhf.deb" --output libmimalloc-dev_2.0.5+ds-2_armhf.deb \
#     && dpkg-deb -xv libmimalloc-dev_2.0.5+ds-2_armhf.deb libmimalloc \
#     && curl -L "http://launchpadlibrarian.net/587654481/libmimalloc2.0_2.0.5+ds-2_armhf.deb" --output libmimalloc2.0_2.0.5+ds-2_armhf.deb \
#     && dpkg-deb -xv libmimalloc2.0_2.0.5+ds-2_armhf.deb libmimalloc \
#     && cp -r /polars/libmimalloc/usr/lib/arm-linux-gnueabihf/* /usr/armv7-unknown-linux-gnueabihf/armv7-unknown-linux-gnueabihf/sysroot/usr/lib && ls -l /usr/armv7-unknown-linux-gnueabihf/armv7-unknown-linux-gnueabihf/bin/../sysroot/usr/lib/
RUN curl -L "https://github.com/pola-rs/polars/archive/refs/tags/${TARGET_POLARS_TAG}.tar.gz" | tar --absolute-names -xzf - && mv polars-${TARGET_POLARS_TAG} polars
WORKDIR /polars/polars
RUN . $HOME/.cargo/env \
    && sed -i "s/--upgrade --compile-bytecode --no-build/--upgrade --compile-bytecode/" Makefile
# RUN sed -i "s/mimalloc = { version = \"0.1\", default-features = false }/system-mimalloc = { version = \"1.0.0\" }/" py-polars/Cargo.toml \
#     && cat py-polars/Cargo.toml \
#     && sed -i "s/static ALLOC: mimalloc::MiMalloc = mimalloc::MiMalloc;/static ALLOC: system_mimalloc::MiMalloc = system_mimalloc::MiMalloc;/" py-polars/src/allocator.rs \
#     && cat py-polars/src/allocator.rs
RUN . $HOME/.cargo/env \
    && rustup target add ${TARGET_ARCH}-${TARGET_ARCH_POSTFIX}
RUN ldd --version
RUN . $HOME/.cargo/env && export RUSTFLAGS="${RUSTFLAGS} --cfg allocator=\"mimalloc\"" && maturin build --target ${TARGET_ARCH}-${TARGET_ARCH_POSTFIX} --compatibility manylinux_2_28 --auditwheel=skip -j${CPU_COUNT} --profile dev --manifest-path py-polars/Cargo.toml --features tikv-jemallocator/stats,tikv-jemallocator/debug\
,mimalloc/debug,mimalloc/debug_in_debug \
     && echo ""




FROM ubuntu:jammy-20250404 AS tg-zmt-bot_dependencies_armv7
COPY --from=dependencies-builder /polars/polars/target/wheels /wheels
RUN ls /wheels

