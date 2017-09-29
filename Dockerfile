FROM rawmind/alpine-monit:0.5.20-4
MAINTAINER romracer <romracer@gmail.com>

# Set environment
ENV SERVICE_NAME=traefik \
    SERVICE_HOME=/opt/traefik \
    SERVICE_VERSION=v1.3.8 \
    SERVICE_UID=10001 \
    SERVICE_GID=10001 \
    SERVICE_USER=traefik \
    SERVICE_GROUP=traefik \
    SERVICE_URL=https://github.com/containous/traefik/releases/download
ENV SERVICE_RELEASE=${SERVICE_URL}/${SERVICE_VERSION}/traefik_linux-amd64 \
    PATH=${PATH}:${SERVICE_HOME}/bin 

# Download and install traefik
RUN mkdir -p ${SERVICE_HOME}/bin ${SERVICE_HOME}/certs ${SERVICE_HOME}/etc ${SERVICE_HOME}/log && \
    apk add --no-cache libcap  && \
    cd ${SERVICE_HOME}/bin && \
    curl -jksSL "${SERVICE_RELEASE}" -O && \
    mv traefik_linux-amd64 traefik && \
    addgroup -g ${SERVICE_GID} ${SERVICE_GROUP} && \
    adduser -g "${SERVICE_NAME} user" -D -h ${SERVICE_HOME} -G ${SERVICE_GROUP} -s /sbin/nologin -u ${SERVICE_UID} ${SERVICE_USER} 
ADD root /
RUN chmod +x ${SERVICE_HOME}/bin/* && \
    chown -R ${SERVICE_USER}:${SERVICE_GROUP} ${SERVICE_HOME} /opt/monit && \
    setcap 'cap_net_bind_service=+ep' ${SERVICE_HOME}/bin/traefik

USER $SERVICE_USER
WORKDIR $SERVICE_HOME
