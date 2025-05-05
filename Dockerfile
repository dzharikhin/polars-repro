# syntax=docker/dockerfile-upstream:master
FROM ubuntu:jammy-20250404 AS linux.arm.v7-builder
ENV QEMU_CPU=cortex-a15
ARG POETRY_VERSION=1.8.5

ENV POETRY_HOME=/opt/poetry
ENV POETRY_VIRTUALENVS_IN_PROJECT=1
ENV POETRY_VIRTUALENVS_CREATE=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
# Tell Poetry where to place its cache and virtual environment
ENV POETRY_CACHE_DIR=/opt/.cache

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y software-properties-common curl git
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt update && apt install -y python3-dev python3.12-dev python-is-python3
RUN rm -f /usr/lib/python3.12/EXTERNALLY-MANAGED && curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python get-pip.py setuptools wheel && python -m pip config set global.break-system-packages true
RUN add-apt-repository -s "$(cat /etc/apt/sources.list | grep -E '^deb(.+)$' | head -1 )" && apt update
# https://llvmlite.readthedocs.io/en/latest/admin-guide/install.html#building-manually
RUN pip install cmake==3.31.2 --upgrade && cmake --version && apt install -y ninja-build \
# scipy https://docs.scipy.org/doc/scipy/building/index.html
    gcc g++ gfortran libopenblas-dev liblapack-dev pkg-config python3-dev python3.12-dev \
# pyarrow https://arrow.apache.org/install/
    ca-certificates lsb-release \
    && curl -LO "https://apache.jfrog.io/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb" \
    && apt install -y -V ./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb \
    && apt update \
    && apt install -y -V  build-essential \
# other
    && apt install -y libsqlite3-dev libffi-dev libxml2-dev libxslt-dev && pip install -U pip && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && . $HOME/.cargo/env && pip install "poetry==${POETRY_VERSION}"
# parallel compilation
ARG CPU_COUNT=4
ENV CPU_COUNT=$CPU_COUNT

# WORKDIR /llvm
# ENV TARGET_LLVM_NAME=llvm-project-15.0.7.src
# ENV TARGET_LLVMLITE_TAG=0.44.0
# RUN curl -L "https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.7/${TARGET_LLVM_NAME}.tar.xz" | tar --absolute-names -xJf - && mv ${TARGET_LLVM_NAME} llvm \
#     && curl -L "https://github.com/numba/llvmlite/archive/refs/tags/v${TARGET_LLVMLITE_TAG}.tar.gz" | tar --absolute-names -xzf - && mv llvmlite-${TARGET_LLVMLITE_TAG} llvmlite \
#     && cd llvm && ls ../llvmlite/conda-recipes/llvm15* | xargs -I{} patch -p1 -i {}
# # set = 1 to disable tests
# ARG SKIP_LLVM_TESTS=0
# ENV CONDA_BUILD_CROSS_COMPILATION=$SKIP_LLVM_TESTS
# ENV PREFIX=/usr/local
# RUN cd /llvm/llvm && bash ../llvmlite/conda-recipes/llvmdev/build.sh

#create virtualenv - poetry works with venv, so no system python
WORKDIR /app
COPY pyproject.toml poetry.lock /app/
RUN poetry env use 3.12 && poetry env list && which python
# https://llvmlite.readthedocs.io/en/latest/admin-guide/install.html#building-manually
# https://github.com/pola-rs/polars#python-compile-polars-from-source
RUN . /app/.venv/bin/activate && which python && pip install -U pip setuptools maturin[patchelf]

WORKDIR /app
ARG POETRY_INSTALLER_MAX_WORKERS=4
ENV POETRY_INSTALLER_MAX_WORKERS=$POETRY_INSTALLER_MAX_WORKERS
WORKDIR /wheels
COPY --from=dependencies_arm /wheels /wheels
RUN . /app/.venv/bin/activate && ls | xargs -I{} pip install {} \
    && pip list --format=freeze
WORKDIR /app
RUN apt install -y
RUN . /app/.venv/bin/activate && cd /app && . $HOME/.cargo/env \
    && export WHL=/wheels/$(ls /wheels | grep "polars-") && sed -i -E "s:polars =.+:polars = { path=\"$WHL\" }:" pyproject.toml && poetry lock --no-update \
    && poetry -vv install --no-root && rm -rf $POETRY_CACHE_DIR




FROM ubuntu:jammy-20250404 AS runtime
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y software-properties-common curl
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt update && apt install -y python3.12 python-is-python3 libopenblas0 liblapack3 libsndfile1 libgomp1
# mimalloc as package
RUN apt install -y libmimalloc2.0
# debug
RUN apt install -y rust-gdb python3.12-dbg valgrind libc6-dbg libmimalloc-dev
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/app/.venv/bin:$PATH"

COPY --from=linux.arm.v7-builder /usr/local /usr/local
COPY --from=linux.arm.v7-builder /app/.venv /app/.venv
COPY . /app

WORKDIR /app
ENTRYPOINT ["python"]
CMD ["main.py"]