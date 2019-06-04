# docker build \
#   --tag autobdd-dev:1.0.0 \
#   --build-arg AutoBDD_Ver=1.0.0 \
#   --file autobdd-dev.dockerfile \
#   ${PWD}
#
# docker run -d --rm=true --privileged \
#   -p 6080:80 \
#   -p 5901:5900 \
#   -p 2222:22 \
#   -e USER=${USER} \
#   -e RESOLUTION=1920x1200 \
#   -e ENVVAR1=env_var_1 \
#   -e ENVVAR2=env_var_2 \
#   -v ~/.ssh:/home/${USER}/.ssh:rw \
#   -v ~/.m2:/home/${USER}/.m2:rw \
#   -v ~/Projects/${BDD_PROJECT}:/home/${USER}/Projects/AutoBDD/test-projects/${BDD_PROJECT} \
#   --shm-size 1024M \
#   autobdd-dev:1.0.0

FROM dorowu/ubuntu-desktop-lxde-vnc:latest
USER root
ENV USER root
ENV DEBIAN_FRONTEND noninteractive
ARG AutoBDD_Ver

# full upgrade
RUN apt clean -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" && \
    apt update -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" && \
    apt full-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" 

# apt install essential tools for apt install/upgrade
RUN apt install -q -y --allow-unauthenticated --fix-missing --no-install-recommends -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
    apt-utils \
    wget

# Set the timezone.
RUN sudo dpkg-reconfigure -f noninteractive tzdata

# install standard linux tools needed for automation framework
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
    less \
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
    unzip \
    wmctrl \
    x11vnc \
    xclip \
    xdg-utils \
    xdotool \
    xvfb \
    zlib1g-dev

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

# install nodejs 
RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - && \
    apt update -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"  && \
    apt install -q -y --allow-unauthenticated --fix-missing -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
    nodejs

# final autoremove
RUN apt update -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" && \
    apt --purge autoremove -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# configure to start sshd
RUN mkdir -p /var/run/sshd && echo "\n\n[program:sshd]\npriority=10\ncommand=/usr/sbin/sshd -d\nstopsignal=KILL\n\n" >> /etc/supervisor/conf.d/supervisord.conf

# run finishing set up
RUN update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java; \
    ln -s /usr/lib/jni/libopencv_java*.so /usr/lib/libopencv_java.so; \
    /usr/sbin/locale-gen "en_US.UTF-8"; echo LANG="en_US.UTF-8" > /etc/locale.conf; \
    mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix

# download AutoBDD
RUN mkdir -p /${USER}/Projects && cd /${USER}/Projects && \
    curl -Lo- https://github.com/xyteam/AutoBDD/archive/${AutoBDD_Ver}.tar.gz | gzip -cd | tar xf - && \
    mv AutoBDD-${AutoBDD_Ver} AutoBDD

# create convenient alias for AutoBDD
RUN echo "alias spr='rsync --human-readable --progress --update --archive --exclude .git/ --exclude node_modules/ --exclude xyPlatform/ \${HOME}/Projects/ \${HOME}/Run'" > /${USER}/.bashrc && \
    echo "alias srp='rsync --human-readable --progress --update --archive --exclude node_modules/ --exclude target/ --exclude logs/ \${HOME}/Run/ \${HOME}/Projects'" >> /${USER}/.bashrc && \
    echo "alias xvfb-auto='xvfb-run --auto-servernum --server-args=\"-screen 0 1920x1200x16\"'" >> /${USER}/.bashrc && \
    chmod +x /${USER}/.bashrc

# upon launch set .bashrc for the running user and let running user take over the Projects folder
RUN sed -i "/^exec \/bin\/tini .*/i cat /root/.bashrc >> \$HOME/.bash_profile && chown \$USER:\$USER \$HOME/.bash_profile\n" /startup.sh && \
    sed -i "/^exec \/bin\/tini .*/i cd /root && tar cf - ./Projects | (cd \$HOME && tar xf -) && chown -R \$USER:\$USER \$HOME/Projects\n" /startup.sh && \
    sed -i "/^exec \/bin\/tini .*/i sudo su \$USER -E -c \"cd \$HOME/Projects/AutoBDD && npm install && source .autoPathrc.sh && xvfb-run -a npm run test-init\"" /startup.sh

EXPOSE 5900
EXPOSE 22
EXPOSE 80
