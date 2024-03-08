FROM rockylinux:8

LABEL org.opencontainers.image.source="https://github.com/giovtorres/slurm-docker-cluster" \
    org.opencontainers.image.title="slurm-docker-cluster" \
    org.opencontainers.image.description="Slurm Docker cluster on Rocky Linux 8" \
    org.label-schema.docker.cmd="docker-compose up -d" \
    maintainer="Giovanni Torres"

ARG SLURM_TAG=slurm-21-08-6-1
ARG GOSU_VERSION=1.11

RUN set -ex \
    && yum makecache \
    && yum -y update \
    && yum -y install dnf-plugins-core \
    && yum config-manager --set-enabled powertools \
    && yum -y install \
    wget \
    bzip2 \
    perl \
    gcc \
    gcc-c++\
    git \
    gnupg \
    make \
    munge \
    munge-devel \
    python3-devel \
    python3-pip \
    python3 \
    mariadb-server \
    mariadb-devel \
    psmisc \
    bash-completion \
    vim-enhanced \
    http-parser-devel \
    json-c-devel \
    && yum clean all \
    && rm -rf /var/cache/yum

RUN alternatives --set python /usr/bin/python3

RUN pip3 install Cython nose

RUN set -ex \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -rf "${GNUPGHOME}" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

RUN git clone --depth 1 --single-branch -b v2.9.4 https://github.com/nodejs/http-parser.git http_parser \
    && cd http_parser \
    && make \
    && make install

RUN yum install -y autoconf cmake3 automake \
    && git clone --depth 1 --single-branch -b json-c-0.15-20200726 https://github.com/json-c/json-c.git json-c \
    && mkdir json-c-build \
    && cd json-c-build \
    && cmake ../json-c \
    && make \
    && make install

ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/:$PKG_CONFIG_PATH

RUN yum install -y libtool \
    && git clone --depth 1 --single-branch -b 0.2.5 https://github.com/yaml/libyaml libyaml \
    && cd libyaml \
    && ./bootstrap \
    && ./configure \
    && make \
    && make install 

RUN yum install -y json-c-devel http-parser-devel autoconf cmake3 automake libtool \
    && wget https://github.com/akheron/jansson/releases/download/v2.14/jansson-2.14.tar.bz2 \
    && tar -xf jansson-2.14.tar.bz2 \
    && cd jansson-2.14 \
    && ./configure --prefix=/usr/local \
    && make \
    && make install 

RUN groupadd -r --gid=1200 rest \
    && useradd -r -g rest --uid=1200 rest \
    && git clone --depth 1 --single-branch -b v1.12.0 https://github.com/benmcollins/libjwt.git libjwt \
    && cd libjwt \
    && autoreconf --force --install \
    && ./configure JANSSON_CFLAGS=-I/usr/include JANSSON_LIBS="-L/usr/lib -ljansson" --prefix=/usr/local \
    && make \
    && make install \
    && cp /usr/local/lib/libjwt.* /lib64

RUN set -x \
    && git clone -b ${SLURM_TAG} --single-branch --depth=1 https://github.com/SchedMD/slurm.git \
    && pushd slurm \
    && ./configure --enable-debug --prefix=/usr --sysconfdir=/etc/slurm --with-yaml=/usr/local/ \
    --with-mysql_config=/usr/bin  --libdir=/usr/lib64 --with-jwt=/usr/local/ --with-http-parser=/usr/local/ \
    && make install \
    && install -D -m644 etc/cgroup.conf.example /etc/slurm/cgroup.conf.example \
    && install -D -m644 etc/slurm.conf.example /etc/slurm/slurm.conf.example \
    && install -D -m644 etc/slurmdbd.conf.example /etc/slurm/slurmdbd.conf.example \
    && install -D -m644 contribs/slurm_completion_help/slurm_completion.sh /etc/profile.d/slurm_completion.sh \
    && popd \
    && rm -rf slurm \
    && groupadd -r --gid=990 slurm \
    && useradd -r -g slurm --uid=990 slurm \
    && mkdir /etc/sysconfig/slurm \
    /var/spool/slurmd \
    /var/run/slurmd \
    /var/run/slurmdbd \
    /var/lib/slurmd \
    /var/log/slurm \
    /data \
    && touch /var/lib/slurmd/node_state \
    /var/lib/slurmd/front_end_state \
    /var/lib/slurmd/job_state \
    /var/lib/slurmd/resv_state \
    /var/lib/slurmd/trigger_state \
    /var/lib/slurmd/assoc_mgr_state \
    /var/lib/slurmd/assoc_usage \
    /var/lib/slurmd/qos_usage \
    /var/lib/slurmd/fed_mgr_state \
    && chown -R slurm:slurm /var/*/slurm* \
    && /sbin/create-munge-key

COPY slurm.conf /etc/slurm/slurm.conf

COPY slurmdbd.conf /etc/slurm/slurmdbd.conf

COPY slurmrestd.sh /usr/share/bin/slurmrestd.sh

RUN set -x \
    && chown slurm:slurm /etc/slurm/slurmdbd.conf \
    && chmod 600 /etc/slurm/slurmdbd.conf \
    && chown slurm:slurm /etc/slurm/slurm.conf \
    && chmod 0755 /etc/slurm/slurm.conf \
    && chown slurm:slurm /usr/share/bin/slurmrestd.sh \
    && chmod 0755 /usr/share/bin/slurmrestd.sh \
    && usermod -a -G slurm rest

RUN mkdir -p /var/spool/slurm/statesave \
    && dd if=/dev/random of=/var/spool/slurm/statesave/jwt_hs256.key bs=32 count=1 \
    && chown slurm:slurm /var/spool/slurm/statesave/jwt_hs256.key \
    && chmod 0600 /var/spool/slurm/statesave/jwt_hs256.key \
    && chown slurm:slurm /var/spool/slurm/statesave \
    && chmod 0755 /var/spool/slurm/statesave 

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh 

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["slurmdbd"]
