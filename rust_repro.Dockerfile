# syntax=docker/dockerfile-upstream:master
FROM ubuntu:jammy-20250404 AS runtime
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y software-properties-common curl
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt install -y rust-gdb valgrind libc6-dbg
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/app/.venv/bin:$PATH"

COPY --from=dependencies-builder /rust_repro/ /rust_repro/

WORKDIR /rust_repro
ENTRYPOINT ["/rust_repro/rust_repro"]
