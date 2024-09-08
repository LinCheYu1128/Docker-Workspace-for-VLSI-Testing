# install python packages
FROM ubuntu:20.04 AS python_pkg_provider
RUN apt-get -y update && \
    apt-get -y install python3 python3-pip build-essential
COPY ./config/requirements.txt /tmp/requirements.txt


# main stage
FROM ubuntu:20.04 AS base

ARG UID=1000
ARG GID=1000
ARG USERNAME="user"
ARG TZ="Asia/Taipei"

ENV INSTALLATION_TOOLS=" \
    apt-utils \
    sudo \
    curl \
    wget \
    software-properties-common \
"

ENV PYTHON_PACKAGES=" \
    python3 \
    python3-pip \
    python-is-python3 \
"

ENV DEVELOPMENT_PACKAGES=" \
    build-essential \
    flex \
    bison \
    valgrind \
    make \
    gdb \
    ca-certificates-java \
    openjdk-8-jdk \
    cmake \
    flatbuffers-compiler \
    libreadline-dev \
    libncurses5-dev \
"

ENV TOOL_PACKAGES=" \
    bash \
    dos2unix \
    git \
    locales \
    nano \
    tree \
    vim \
    emacs \
    tmux \
"

ENV USER="${USERNAME}"
ENV TERM=xterm-256color
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

# install system packages
RUN apt-get -y update
RUN apt-get -y install ${INSTALLATION_TOOLS}

# prerequisite - git
RUN add-apt-repository ppa:git-core/ppa

# start install
RUN apt-get -y update && apt-get -y upgrade
RUN apt-get -y install ${PYTHON_PACKAGES}
RUN apt-get -y install ${DEVELOPMENT_PACKAGES}
RUN apt-get -y install ${TOOL_PACKAGES}

# set env var JAVA_HOME
ENV JAVA_HOME="/usr/lib/jvm/java-8-openjdk-*"

# install conda
ARG TARGETARCH
RUN if [ [ "${TARGETARCH}" = "arm64" ] ]; then \
     wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh -O /tmp/miniconda.sh; \
     else \
     wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh; \
     fi
RUN /bin/bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh && \
    echo "export PATH=/opt/conda/bin:$PATH" > /etc/profile.d/conda.sh
ENV PATH /opt/conda/bin:$PATH


# Add alias for jupyter commands
RUN echo "alias run-jupyter=\"jupyter notebook --NotebookApp.iopub_data_rate_limit=1.0e10 --ip 0.0.0.0 --port 8888 --no-browser --allow-root >jupyter.stdout.log &>jupyter.stderr.log &\" " >> /opt/conda/etc/profile.d/conda.sh

# setup time zone
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

# add support of locale zh_TW
RUN sed -i 's/# en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen && \
    sed -i 's/# zh_TW.UTF-8/zh_TW.UTF-8/g' /etc/locale.gen && \
    sed -i 's/# zh_TW BIG5/zh_TW BIG5/g' /etc/locale.gen && \
    locale-gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# add non-root user account
RUN groupadd -o -g ${GID} "${USERNAME}" && \
    useradd -u ${UID} -m -s /bin/bash -g ${GID} "${USERNAME}" && \
    echo "${USERNAME} ALL = NOPASSWD: ALL" > /etc/sudoers.d/"${USERNAME}" && \
    chmod 0440 /etc/sudoers.d/"${USERNAME}" && \
    passwd -d "${USERNAME}"

# add scripts and setup permissions
COPY --chown=${UID}:${GID} ./scripts/.bashrc /home/"${USERNAME}"/.bashrc
COPY --chown=${UID}:${GID} ./scripts/start.sh /docker/start.sh
COPY --chown=${UID}:${GID} ./scripts/login.sh /docker/login.sh
COPY --chown=${UID}:${GID} ./scripts/startup.sh /usr/local/bin/startup
RUN dos2unix -ic "/home/${USERNAME}/.bashrc" | xargs dos2unix && \
    dos2unix -ic "/docker/start.sh" | xargs dos2unix && \
    dos2unix -ic "/docker/login.sh" | xargs dos2unix && \
    dos2unix -ic "/usr/local/bin/startup" | xargs dos2unix && \
    chmod +x "/usr/local/bin/startup"

# user account configuration
RUN mkdir -p /home/"${USERNAME}"/.ssh && \
    mkdir -p /home/"${USERNAME}"/.vscode-server && \
    mkdir -p /home/"${USERNAME}"/projects && \
    mkdir -p /home/"${USERNAME}"/.local
RUN chown -R ${UID}:${GID} /home/"${USERNAME}"

# install python libraries
# RUN pip3 install --upgrade pip wheel
# COPY --from=python_pkg_provider --chown=${UID}:${GID} /root/.local /home/"${USERNAME}"/.local

ENV PATH="${PATH}:/home/${USERNAME}/.local/bin"

# TensorBoard setup
EXPOSE 10000

USER "${USERNAME}"

WORKDIR /home/"${USERNAME}"

CMD [ "bash", "/docker/start.sh" ]
