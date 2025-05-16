# syntax=docker/dockerfile-upstream:master
FROM ghcr.io/rust-cross/manylinux_2_28-cross:armv7 AS dependencies-builder
ENV TARGET_ARCH=armv7-unknown-linux
ENV TARGET_ARCH_POSTFIX=gnueabihf
ENV CC_ENABLE_DEBUG_OUTPUT=1
ENV RUSTFLAGS="-g"

RUN getconf PAGE_SIZE
RUN apt update
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ARG CPU_COUNT=4
ENV CPU_COUNT=$CPU_COUNT
ARG CARGO_BUILD_JOBS=4
ENV CARGO_BUILD_JOBS=$CARGO_BUILD_JOBS

COPY rust_repro/ /rust_repro/
WORKDIR /rust_repro
RUN ls .
RUN . $HOME/.cargo/env \
    && rustup target add ${TARGET_ARCH}-${TARGET_ARCH_POSTFIX}
RUN ldd --version
RUN . $HOME/.cargo/env && cargo build --target ${TARGET_ARCH}-${TARGET_ARCH_POSTFIX} --profile dev --features mimalloc/debug,mimalloc/debug_in_debug
RUN cp target/${TARGET_ARCH}-${TARGET_ARCH_POSTFIX}/debug/rust_repro .

