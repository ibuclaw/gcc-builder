FROM ubuntu:22.04

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC \
    apt-get install -y apt-transport-https bzip2 curl dirmngr git gpg-agent \
            software-properties-common xz-utils unzip \
            autogen autoconf automake bison dejagnu flex make patch \
            libcurl4-gnutls-dev libgmp-dev libisl-dev libmpc-dev libmpfr-dev tzdata \
            gcc-multilib g++-multilib gdc-multilib binutils libc6-dev \
            amdgcn-tools
RUN mkdir -p /srv/gdcexplorer/gcc-builder
RUN useradd -r -u 998 -d /srv/gdcexplorer gdcexplorer

WORKDIR /srv/gdcexplorer/gcc-builder
USER gdcexplorer
CMD /srv/gdcexplorer/gcc-builder/build.sh
