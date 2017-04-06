#!/usr/bin/env sh

TRAEFIK_HTTP_PORT=${TRAEFIK_HTTP_PORT:-"8080"}
TRAEFIK_HTTPS_ENABLE=${TRAEFIK_HTTPS_ENABLE:-"false"}
TRAEFIK_HTTPS_PORT=${TRAEFIK_HTTPS_PORT:-"8443"}
TRAEFIK_ADMIN_PORT=${TRAEFIK_ADMIN_PORT:-"8000"}
TRAEFIK_LOG_LEVEL=${TRAEFIK_LOG_LEVEL:-"INFO"}
TRAEFIK_LOG_FILE=${TRAEFIK_LOG_FILE:-"${SERVICE_HOME}/log/traefik.log"}
TRAEFIK_ACCESS_FILE=${TRAEFIK_ACCESS_FILE:-"${SERVICE_HOME}/log/access.log"}
TRAEFIK_SSL_PATH=${TRAEFIK_SSL_PATH:-"${SERVICE_HOME}/certs"}
TRAEFIK_ACME_ENABLE=${TRAEFIK_ACME_ENABLE:-"false"}
TRAEFIK_ACME_EMAIL=${TRAEFIK_ACME_EMAIL:-"test@traefik.io"}
TRAEFIK_ACME_ONDEMAND=${TRAEFIK_ACME_ONDEMAND:-"true"}
TRAEFIK_ACME_ONHOSTRULE=${TRAEFIK_ACME_ONHOSTRULE:-"true"}
TRAEFIK_ACME_DNSPROVIDER=${TRAEFIK_ACME_DNSPROVIDER:-""}
TRAEFIK_K8S_ENABLE=${TRAEFIK_K8S_ENABLE:-"false"}
TRAEFIK_K8S_OPTS=${TRAEFIK_K8S_OPTS:-""}

TRAEFIK_ENTRYPOINTS_HTTP="\
  [entryPoints.http]
  address = \":${TRAEFIK_HTTP_PORT}\"
"

filelist=`ls -1 ${TRAEFIK_SSL_PATH}/*.key | cut -d"." -f1`
RC=`echo $?`

if [ $RC -eq 0 ]; then
    TRAEFIK_ENTRYPOINTS_HTTPS="\
  [entryPoints.https]
  address = \":${TRAEFIK_HTTPS_PORT}\"
    [entryPoints.https.tls]"
    for i in $filelist; do
        if [ -f "$i.crt" ]; then
            TRAEFIK_ENTRYPOINTS_HTTPS=$TRAEFIK_ENTRYPOINTS_HTTPS"
      [[entryPoints.https.tls.certificates]]
      certFile = \"${i}.crt\"
      keyFile = \"${i}.key\"
"
        fi
    done
fi

if [ "X${TRAEFIK_HTTPS_ENABLE}" == "Xtrue" ]; then
    TRAEFIK_ENTRYPOINTS_OPTS=${TRAEFIK_ENTRYPOINTS_HTTP}${TRAEFIK_ENTRYPOINTS_HTTPS}
    TRAEFIK_ENTRYPOINTS='"http", "https"'
elif [ "X${TRAEFIK_HTTPS_ENABLE}" == "Xonly" ]; then
    TRAEFIK_ENTRYPOINTS_HTTP=$TRAEFIK_ENTRYPOINTS_HTTP"\
    [entryPoints.http.redirect]
       entryPoint = \"https\"
"
    TRAEFIK_ENTRYPOINTS_OPTS=${TRAEFIK_ENTRYPOINTS_HTTP}${TRAEFIK_ENTRYPOINTS_HTTPS}
    TRAEFIK_ENTRYPOINTS='"http", "https"'
else 
    TRAEFIK_ENTRYPOINTS_OPTS=${TRAEFIK_ENTRYPOINTS_HTTP}
    TRAEFIK_ENTRYPOINTS='"http"'
fi

if [ "X${TRAEFIK_K8S_ENABLE}" == "Xtrue" ]; then
    TRAEFIK_K8S_OPTS="[kubernetes]"
fi

TRAEFIK_ACME_CFG=""
if [ "X${TRAEFIK_HTTPS_ENABLE}" == "Xtrue" ] || [ "X${TRAEFIK_HTTPS_ENABLE}" == "Xonly" ] && [ "X${TRAEFIK_ACME_ENABLE}" == "Xtrue" ]; then
    TRAEFIK_ACME_CFG="\
[acme]
email = \"${TRAEFIK_ACME_EMAIL}\"
storage = \"traefik/acme/account\"
onDemand = ${TRAEFIK_ACME_ONDEMAND}
OnHostRule = ${TRAEFIK_ACME_ONHOSTRULE}
entryPoint = \"https\""

    if [ "X${TRAEFIK_ACME_DNSPROVIDER}" != "X" ]; then
        TRAEFIK_ACME_CFG=$TRAEFIK_ACME_CFG"
dnsProvider = \"${TRAEFIK_ACME_DNSPROVIDER}\""
    fi
fi

cat << EOF > ${SERVICE_HOME}/etc/traefik.toml
# traefik.toml
logLevel = "${TRAEFIK_LOG_LEVEL}"
traefikLogsFile = "${TRAEFIK_LOG_FILE}"
accessLogsFile = "${TRAEFIK_ACCESS_FILE}"
defaultEntryPoints = [${TRAEFIK_ENTRYPOINTS}]
[entryPoints]
${TRAEFIK_ENTRYPOINTS_OPTS}
[web]
address = ":${TRAEFIK_ADMIN_PORT}"

${TRAEFIK_K8S_OPTS}

[${KV_BACKEND}]
endpoint = "${KV_ADDRESS}"
watch = true
prefix = "traefik"

[rancher]
domain = "${RANCHER_DEFAULT_DOMAIN}"
Watch = true
ExposedByDefault = ${RANCHER_EXPOSED_DEFAULT}
Endpoint = "${RANCHER_ENDPOINT}"
AccessKey = "${RANCHER_ACCESS_KEY}"
SecretKey = "${RANCHER_SECRET_KEY}"

${TRAEFIK_ACME_CFG}
EOF
