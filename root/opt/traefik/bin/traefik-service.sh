#!/usr/bin/env bash

function log {
        echo `date` $ME - $@
}

function serviceLog {
    log "[ Redirecting ${SERVICE_NAME} log... ]"
    if [ -e ${TRAEFIK_LOG_FILE} ]; then
        rm ${TRAEFIK_LOG_FILE}
    fi
    ln -sf /proc/1/fd/1 ${TRAEFIK_LOG_FILE}
}

function serviceAccess {
    log "[ Redirecting ${SERVICE_NAME} log... ]"
    if [ -e ${TRAEFIK_ACCESS_FILE} ]; then
        rm ${TRAEFIK_ACCESS_FILE}
    fi
    ln -sf /proc/1/fd/1 ${TRAEFIK_ACCESS_FILE}
}

function serviceCheck {
    log "[ Generating ${SERVICE_NAME} configuration... ]"
    ${SERVICE_HOME}/bin/traefik.toml.sh
    log "[ Storing ${SERVICE_NAME} configuration in ${KV_BACKEND}... ]"
    ${SERVICE_HOME}/bin/traefik storeconfig --configfile=${SERVICE_HOME}/etc/traefik.toml
    if [ "X${KV_BACKEND}" == "Xconsul" ] ; then
        curl -XDELETE "http://${KV_ADDRESS}/v1/kv/traefik/acme/storagefile?token=${CONSUL_HTTP_TOKEN}"
    fi
    if [ "X${KV_BACKEND}" == "Xetcd" ] ; then
        curl -XDELETE "http://${KV_ADDRESS}/v2/keys/traefik/acme/storagefile"
    fi
    rm ${SERVICE_HOME}/etc/traefik.toml
}

function serviceStart {
    serviceCheck
    serviceLog
    serviceAccess
    log "[ Starting ${SERVICE_NAME}... ]"
    nohup ${SERVICE_HOME}/bin/traefik --${KV_BACKEND} --${KV_BACKEND}.endpoint=${KV_ADDRESS} &
    echo $! > ${SERVICE_HOME}/traefik.pid
}

function serviceStop {
    log "[ Stoping ${SERVICE_NAME}... ]"
    kill `cat /opt/traefik/traefik.pid`
}

function serviceRestart {
    log "[ Restarting ${SERVICE_NAME}... ]"
    serviceStop
    serviceStart
    /opt/monit/bin/monit reload
}

export TRAEFIK_LOG_FILE=${TRAEFIK_LOG_FILE:-"${SERVICE_HOME}/log/traefik.log"}
export TRAEFIK_ACCESS_FILE=${TRAEFIK_ACCESS_FILE:-"${SERVICE_HOME}/log/access.log"}

case "$1" in
        "start")
            serviceStart &>> /proc/1/fd/1
        ;;
        "stop")
            serviceStop &>> /proc/1/fd/1
        ;;
        "restart")
            serviceRestart &>> /proc/1/fd/1
        ;;
        *) echo "Usage: $0 restart|start|stop"
        ;;
esac
