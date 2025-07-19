ARG BASE_IMAGE=rockylinux:8-minimal
FROM ${BASE_IMAGE}


# Build latest OpenSSL LTS.
ENV OPENSSL_VERSION=3.5.1
ENV OPENSSL_PREFIX=/usr/local/openssl

RUN microdnf update -y \
    && microdnf install -y gcc make perl wget tar git perl-core zlib-devel \
    && microdnf clean all

RUN wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
    tar -xzf openssl-${OPENSSL_VERSION}.tar.gz && \
    cd openssl-${OPENSSL_VERSION} && \
    ./Configure --prefix=${OPENSSL_PREFIX} --openssldir=${OPENSSL_PREFIX} shared zlib && \
    make -j$(nproc) && \
    make install && \
    cd .. && rm -rf openssl-${OPENSSL_VERSION} openssl-${OPENSSL_VERSION}.tar.gz

ENV PATH="${OPENSSL_PREFIX}/bin:$PATH"
ENV LD_LIBRARY_PATH="${OPENSSL_PREFIX}/lib64"


# Build Tk/Tcl 8.6
ENV TCLTK_PREFIX=/opt/tcltk

RUN microdnf install -y \
    libX11-devel \
    libXext-devel \
    libXrender-devel \
    fontconfig-devel \
    freetype-devel \
    libXft-devel \
    && microdnf clean all
RUN mkdir -p /tmp/tkbuild && cd /tmp/tkbuild && \
    wget -q http://downloads.sourceforge.net/tcl/tcl8.6.16-src.tar.gz && \
    wget -q http://downloads.sourceforge.net/tcl/tk8.6.16-src.tar.gz && \
    tar xzf tcl8.6.16-src.tar.gz && \
    tar xzf tk8.6.16-src.tar.gz
RUN cd /tmp/tkbuild/tcl8.6.16/unix && \
    ./configure --prefix=${TCLTK_PREFIX} && \
    make -j$(nproc) && \
    make install
RUN cd /tmp/tkbuild/tk8.6.16/unix && \
    ./configure --prefix=${TCLTK_PREFIX} --with-tcl=${TCLTK_PREFIX}/lib && \
    make -j$(nproc) && \
    make install

ENV CPPFLAGS="-I${TCLTK_PREFIX}/include -I${TCLTK_PREFIX}/include/tcl8.6 -I${OPENSSL_PREFIX}/include"
ENV LDFLAGS="-L${TCLTK_PREFIX}/lib -L${OPENSSL_PREFIX}/lib64"
ENV LD_LIBRARY_PATH="${TCLTK_PREFIX}/lib:${OPENSSL_PREFIX}/lib64"
ENV PKG_CONFIG_PATH="${TCLTK_PREFIX}/lib/pkgconfig"


# Build latest Python 3.11
ENV PYTHON3_VERSION=3.11.13
ENV PYTHON_PREFIX=/opt/python/${PYTHON3_VERSION}
ENV PYTHON_BIN=${PYTHON_PREFIX}/bin

RUN microdnf install -y \
    bzip2-devel \
    libffi-devel \
    sqlite \
    sqlite-devel \
    xz-devel \
    && microdnf clean all

RUN cd /tmp && \
    wget https://www.python.org/ftp/python/${PYTHON3_VERSION}/Python-${PYTHON3_VERSION}.tgz && \
    tar xzf Python-${PYTHON3_VERSION}.tgz && \
    cd Python-${PYTHON3_VERSION} && \
    CPPFLAGS="-I${OPENSSL_PREFIX}/include" \
    LDFLAGS="-L${OPENSSL_PREFIX}/lib64" \
    ./configure \
        --prefix=${PYTHON_PREFIX} \
        --enable-optimizations \
        --with-lto \
        --with-computed-gotos \
        --with-system-ffi \
        --enable-shared \
        --enable-loadable-sqlite-extensions \
        --with-openssl=${OPENSSL_PREFIX} && \
    make -j"$(nproc)" && \
    make altinstall && \
    cd / && rm -rf /tmp/Python-${PYTHON3_VERSION} /tmp/Python-${PYTHON3_VERSION}.tgz

ENV PATH="${PYTHON_BIN}:${PATH}"
ENV LD_LIBRARY_PATH="${PYTHON_PREFIX}/lib:${LD_LIBRARY_PATH}"

RUN ln -s ${PYTHON_BIN}/python3.11         ${PYTHON_BIN}/python3 && \
    ln -s ${PYTHON_BIN}/python3.11         ${PYTHON_BIN}/python && \
    ln -s ${PYTHON_BIN}/pip3.11            ${PYTHON_BIN}/pip3 && \
    ln -s ${PYTHON_BIN}/pip3.11            ${PYTHON_BIN}/pip && \
    ln -s ${PYTHON_BIN}/pydoc3.11          ${PYTHON_BIN}/pydoc && \
    ln -s ${PYTHON_BIN}/idle3.11           ${PYTHON_BIN}/idle && \
    ln -s ${PYTHON_BIN}/python3.11-config  ${PYTHON_BIN}/python-config
RUN ${PYTHON_BIN}/python3.11 -m pip install --upgrade pip setuptools wheel
