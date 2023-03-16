FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

# Space-separated version string without leading 'v' (e.g. "0.4.21 0.4.22") 
ARG SOLC

RUN apt-get update \
  && apt-get install -y \
     libsqlite3-0 \
     libsqlite3-dev \
  && apt-get install -y \
     apt-utils \
     build-essential \
     locales \
     python3-pip \
     python3-setuptools \
     software-properties-common cmake \
  && add-apt-repository -y ppa:ethereum/ethereum \
  && apt-get update \
  && apt-get install -y \
     libssl-dev \
     python3-dev \
     pandoc \
     git \
     wget \
     vim \
     curl \
  && ln -s /usr/bin/python3 /usr/local/bin/python

COPY ./requirements.txt /opt/mythril/requirements.txt

RUN pip install solc-select \
    && solc-select install 0.8.13 \
    && solc-select use 0.8.13

# Install Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup override set nightly

RUN pip install maturin

RUN cd /opt/mythril \
  && pip install -r requirements.txt

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.en
ENV LC_ALL en_US.UTF-8

COPY . /opt/mythril
RUN cd /opt/mythril \
  && python setup.py install

RUN ( [ ! -z "${SOLC}" ] && set -e && for ver in $SOLC; do python -m solc.install v${ver}; done ) || true

COPY ./mythril/support/assets/signatures.db /home/mythril/.mythril/signatures.db

ENTRYPOINT ["/bin/bash"]
