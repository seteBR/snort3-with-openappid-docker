FROM centos:7
MAINTAINER Julian Wang <traceflight@outlook.com>

ENV DAQ_VERSION 2.2.2
ENV SNORT_VERSION 3.0.0
ENV SNORT_EXTRA_VERSION 1.0.0
ENV OPENAPPID_VERSION 8373

ENV PKG_CONFIG /usr/bin/pkg-config
ENV PKG_CONFIG_PATH /usr/share/pkgconfig:/usr/lib64/pkgconfig:/usr/local/snort/lib/pkgconfig:/usr/local/snort/lib64/pkgconfig
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/usr/lib:/usr/local/lib
ENV LUA_PATH /usr/local/snort/include/snort/lua/\?.lua\;\;
ENV SNORT_LUA_PATH /usr/local/snort/etc/
ENV PATH $PATH:/usr/local/snort/bin

ADD etc /usr/local/snort/etc
ADD rules /usr/local/snort/rules
ADD custom /usr/local/snort/appid/custom

# install epel-release
RUN mkdir -p /home/snort/apps && \
    yum -y update ca-certificates && \
    yum -y install epel-release wget gcc git automake autoconf libtool make gcc-c++ && \
    yum clean all && \
    yum makecache && \
    yum -y update
    
# install requirements
RUN yum -y install libnetfilter_queue-devel libunwind-devel gperftools-libs gperftools-devel sqlite-devel libdnet-devel hwloc-devel luajit-devel openssl-devel zlib-devel libpcap-devel zlib-devel lzma xz-devel bison flex && \
    ldconfig

# install cmake
RUN yum remove cmake && \
    cd /home/snort/apps && \
    wget https://cmake.org/files/v3.12/cmake-3.12.0.tar.gz && \
    tar xf cmake-3.12.0.tar.gz && cd cmake-3.12.0 && \
    ./configure && \
    make && \
    make install

# install pcre
RUN cd /home/snort/apps && \
    wget https://ftp.pcre.org/pub/pcre/pcre-8.41.tar.gz && \
    tar xf pcre-8.41.tar.gz && cd pcre-8.41 && \
    ./configure --libdir=/usr/lib64 --includedir=/usr/include && \
    make && \
    make install
    
# install daq
RUN cd /home/snort/apps && \
    wget https://www.snort.org/downloads/snortplus/daq-${DAQ_VERSION}.tar.gz -O daq-${DAQ_VERSION}.tar.gz && \
    tar -zxvf daq-${DAQ_VERSION}.tar.gz && \
    cd daq-${DAQ_VERSION} && \
    ./configure && \
    make && \
    make install && \
    ldconfig
    
# install ragel boost hyperscan
RUN cd /home/snort/apps && \
    wget http://www.colm.net/files/ragel/ragel-6.10.tar.gz && \
    tar xf ragel-6.10.tar.gz && cd ragel-6.10 && \
    ./configure && \
    make && \
    make install && \
    cd /home/snort/apps && \
    wget https://dl.bintray.com/boostorg/release/1.67.0/source/boost_1_67_0.tar.gz && \
    tar xf boost_1_67_0.tar.gz && \
    cd /home/snort/apps && \
    wget https://github.com/intel/hyperscan/archive/v5.0.0.tar.gz -O hyperscan-5.0.0.tar.gz && \
    tar xf hyperscan-5.0.0.tar.gz && \
    mkdir hs-build && cd hs-build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DBOOST_ROOT=../boost_1_67_0 ../hyperscan-5.0.0 && \
    make && \
    make install && \
    cp /usr/local/lib64/pkgconfig/libhs.pc /usr/lib64/pkgconfig/

# install snort3
RUN cd /home/snort/apps && \
    git clone https://github.com/snort3/snort3.git && \
    cd snort3/ && \
    ./configure_cmake.sh --prefix=/usr/local/snort --enable-tcmalloc && \
    cd build/ && \
    make && \
    make install

# install snort_extra
RUN cd /home/snort/apps && \
    git clone https://github.com/snort3/snort3_extra.git && \
    cd snort3_extra && \
    ./configure_cmake.sh --prefix=/usr/local/snort/extra && \
    cd build/ && \
    make && \
    make install

# update community rules
RUN cd /home/snort/apps && \
    wget https://www.snort.org/downloads/community/snort3-community-rules.tar.gz -O snort3-community-rules.tar.gz && \
    tar -xvf snort3-community-rules.tar.gz && \
    cp snort3-community-rules/snort3-community.rules /usr/local/snort/rules/rules/ && \
    cp snort3-community-rules/sid-msg.map /usr/local/snort/rules/rules/

# install openappid
RUN cd /home/snort/apps && \
    wget https://www.snort.org/downloads/openappid/${OPENAPPID_VERSION} -O snort-openappid.tar.gz && \
    tar -zxvf snort-openappid.tar.gz && \
    cp -R odp /usr/local/snort/appid/

# Cleanup.
RUN yum clean all && \
    cd / && \
    rm -rf /var/log/* || true && \
    rm -rf /var/tmp/* && \
    rm -rf /tmp/*

RUN snort -V
