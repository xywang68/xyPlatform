# sudo docker build \
#      --build-arg USER_ID=$(id -u) \
#      --build-arg GROUP_ID=$(id -g) \
#      --tag xyplatform:lubuntu1804 \
#      --file Dockerfile1804 \
#      ${PWD}

FROM ubuntu:18.04
MAINTAINER Xinyu Wang <xywang68@gmail.com>
USER root
ARG USER_ID
ARG GROUP_ID
ENV JAVA_VERSION 8
ENV DEBIAN_FRONTEND noninteractive
# ENV http_proxy http://corporate.proxy:80
# ENV https_proxy http://corporate.proxy:80

# upload files
# ADD environment /etc/environment
# ADD apt.conf /etc/apt/apt.conf
# ADD corporate_cacerts /usr/share/ca-certificates/corporate_cacerts

# apt install essential tools for apt install/upgrade
RUN apt clean -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" 
RUN apt update -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" 
RUN apt full-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" 
RUN apt install -q -y --allow-unauthenticated --fix-missing --no-install-recommends -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
		apt-utils curl wget software-properties-common sudo tzdata
# Set the timezone.
RUN sudo dpkg-reconfigure -f noninteractive tzdata

# # install standard linux tools needed for automation framework
RUN apt install -q -y --allow-unauthenticated --fix-missing --no-install-recommends -o Dpkg::Options::="--force-confdef" \
 -o Dpkg::Options::="--force-confold" \
    autofs \
    binutils \
    build-essential \
    dirmngr \
    ffmpeg \
    fonts-liberation \
    git \
    gpg-agent \
    imagemagick \
    java-common \
    libappindicator3-1 \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libopencv-dev \
    libpython2.7-stdlib \
    libpython3-stdlib \
    libxss1 \
    locales \
    lsof \
    lubuntu-core \
    maven \
    net-tools \
    ntpdate \
    openjdk-8-jdk \
    openjdk-8-jre \
    python2.7-dev \
    python2.7-minimal \
    python3-dev \
    python3-minimal \
    python3-pip \
    python-pip \
    rdesktop \
    rsync \
    sqlite3 \
    openssh-server \  
    tdsodbc \
    tesseract-ocr \
    tree \
    unixodbc \
    unixodbc-dev \
    wmctrl \
    x11vnc \
    xclip \
    xdg-utils \
    xdotool \
    xvfb \
    zlib1g-dev

# sshd and vnc
EXPOSE 222
EXPOSE 5900

# install tinydb used for autorunner framework
RUN pip install tinydb

# install additional tools (chrome and java) needed for automation framework
RUN update-ca-certificates

# instal google-chrome
RUN rm -f /etc/apt/sources.list.d/google-chrome.list && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
 				wget -qO- --no-check-certificate https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
		apt update -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"  && \
				apt install -q -y --allow-unauthenticated --fix-missing -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
				google-chrome-stable

# final autoremove
RUN apt update -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" 
RUN apt --purge autoremove -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
RUN mkdir -p /tmp/.X11-unix
RUN chmod 1777  /tmp/.X11-unix
RUN ln -s /usr/lib/jni/libopencv_java*.so /usr/lib/libopencv_java.so

# run finishing set up
RUN update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
RUN /usr/sbin/locale-gen "en_US.UTF-8"; echo LANG="en_US.UTF-8" > /etc/locale.conf

# create u${USER_ID}:g${GROUP_ID} for l1804Base vagrant
RUN groupadd g${GROUP_ID} -g ${GROUP_ID}
RUN useradd -u ${USER_ID} -g g${GROUP_ID} \
	-m -d /home/u${USER_ID} -s /bin/bash \
	-G sudo \
	-p '$6$sn/6mAt0$NbuFud/aFMN4YdpY2xRMyA5JrH.V212IAGxyRgKji3f2UGSkaXbMujkbG0csPnYoi5ktkgnHaTsHJ20TldwTZ/' \
	u${USER_ID}

# #####################################################################
# This Dockerfile ends here. Below is additional information.
# 
# # To prepare for AutoBDD test, perform this only once:
# wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
# source .bashrc
# nvm install --lts v8
# spr
# cd ~/Run/AutoBDD
# npm install
# . .autoPathrc.sh

# # Spin up docker container and bash inside the docker container:
# sudo docker run -it --rm=true --user=u$(id -u) --privileged \
#   -v $HOME/.m2:/home/u$(id -u)/.m2 \
#   -v $HOME/Run:/home/u$(id -u)/Run \
#   -v $HOME/.bashrc:/home/u$(id -u)/.bashrc \
#   -v $HOME/.pki:/home/u$(id -u)/.pki \
#   -v $HOME/.nvm:/home/u$(id -u)/.nvm \
#   --net=host \
#   --shm-size 256M \
#   xyplatform:lubuntu1804 \
#   /bin/bash

# # Run test manually inside docker container:
# cd
# . .bashrc
# nvm use v8
# cd ~/Run/AutoBDD
# npm rebuild
# . .autoPathrc.sh
# ./framework/scripts/chimp_autorun.py --parallel 2 --movie 1 --platform Linux --browser CH --module test-webpage test-download

# # run test from docker host with 2 docker containers one for each test module (suite):
# sudo docker run -d --rm=true --user=u$(id -u) \
#   -v $HOME/.m2:/home/u$(id -u)/.m2 \
#   -v $HOME/Run:/home/u$(id -u)/Run \
#   -v $HOME/.bashrc:/home/u$(id -u)/.bashrc \
#   -v $HOME/.pki:/home/u$(id -u)/.pki \
#   -v $HOME/.nvm:/home/u$(id -u)/.nvm \
#   --net=host \
#   --shm-size 256M \
#   xyplatform:lubuntu1804 \
#   /bin/bash -c "cd; . .bashrc; . .nvm/nvm.sh; . .nvm/bash_completion; nvm use v8; cd ~/Run/AutoBDD; npm rebuild; . .autoPathrc.sh; ./framework/scripts/chimp_autorun.py --parallel 2 --movie 1 --platform Linux --browser CH --module test-webpage"
# sudo docker run -d --rm=true --user=u$(id -u) --privileged \
#   -v $HOME/.m2:/home/u$(id -u)/.m2 \
#   -v $HOME/Run:/home/u$(id -u)/Run \
#   -v $HOME/.bashrc:/home/u$(id -u)/.bashrc \
#   -v $HOME/.pki:/home/u$(id -u)/.pki \
#   -v $HOME/.nvm:/home/u$(id -u)/.nvm \
#   --net=host \
#   --shm-size 256M \
#   xyplatform:lubuntu1804 \
#   /bin/bash -c "cd; . .bashrc; . .nvm/nvm.sh; . .nvm/bash_completion; nvm use v8; cd ~/Run/AutoBDD; npm rebuild; . .autoPathrc.sh; ./framework/scripts/chimp_autorun.py --parallel 2 --movie 1 --platform Linux --browser CH --module test-download"
# #####################################################################
