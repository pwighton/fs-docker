# Dockerfile to build the dev branch of FreeSurfer
# Based on Ubuntu 16.04 LTS (Xenial Xerus)
#
# It takes `/fs-pkg` and `/fs-code` as input and produces `/fs-bin` 
#
# This environment assumes:
#   - The freesurfer pre-isntalled package directory is: `/fs-pkg`
#   - The freesurfer code directory is: `/fs-code`
#   - The freesurfer install diretory ($FREESURFER_HOME) is: `/fs-bin`
#
# These must be mounted by the user.

FROM ubuntu:xenial

# Complie with gcc/g++ 4.8; to match https://travis-ci.org/github/freesurfer/freesurfer
RUN apt-get update -qq && \
    apt-get install -y -q \
        bc \
        binutils \
        bzip2 \
        curl \
        g++-4.8 \
        gcc-4.8-base \
        gcc-4.8 \
        gfortran-4.8 \
        libbz2-dev \
        libfreetype6-dev \
        libgfortran-4.8-dev \
        libglu1-mesa-dev \
        libgomp1 \
        libjpeg62-dev \
        libopenblas-dev \
        libssl-dev \
        libtool \
        libtool-bin \
        libx11-dev \
        libxaw7-dev \
        libxi-dev \
        libxml2-utils \
        libxmu-dev \
        libxmu-headers \
        libxmu6 \
        libxt-dev \
        libxt6 \
        make \
        perl \
        sudo \
        tar \
        tcsh \
        unzip \
        uuid-dev \
        vim-common \
        wget && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 100 && \
    update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-4.8 100 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install cmake 3.12.3
RUN curl -sSL --retry 5 https://cmake.org/files/v3.12/cmake-3.12.3.tar.gz | tar -xz && \
    cd cmake-3.12.3 && ./configure && make && make install && cd - && \
    rm -rf cmake-3.12.3

# Install Python 3.6, update pip and wheel
RUN curl -sSL --retry 5 https://www.python.org/ftp/python/3.6.5/Python-3.6.5.tgz | tar -xz && \
    cd Python-3.6.5 && ./configure && make -j && make install && cd - && \
    rm -rf Python-3.6.5 Python-3.6.5.tgz 
RUN pip3 install -q --no-cache-dir -U pip && \
    pip3 install -q --no-cache-dir wheel && \
    sync

# Mount point for FreeSurfer binaries (result of compilation)
VOLUME /fs-bin

# Mount point for the FreeSurfer pre-compiled packages 
# http://surfer.nmr.mgh.harvard.edu/pub/data/fspackages/prebuilt/centos7-packages.tar.gz
VOLUME /fs-pkg

# Mount point for FreeSurfer code https://github.com/freesurfer/freesurfer
# Set the workdir to here so we're ready to compile
VOLUME /fs-code
WORKDIR /fs-code
