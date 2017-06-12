[![](https://images.microbadger.com/badges/image/romracer/rancher-traefik.svg)](https://microbadger.com/images/romracer/rancher-traefik "Get your own image badge on microbadger.com")

rancher-traefik 
==============

This image is a traefik base configured to use a Rancher backend. It comes from [alpine-monit][alpine-monit].

## Build

```
docker build -t romracer/rancher-traefik:<version> .
```

## Versions

- `1.3.0-1` [(Dockerfile)](https://github.com/romracer/rancher-traefik/blob/1.3.0-1/Dockerfile)
- `1.2.3-1` [(Dockerfile)](https://github.com/romracer/rancher-traefik/blob/1.2.3-1/Dockerfile)
- `1.2.1-1` [(Dockerfile)](https://github.com/romracer/rancher-traefik/blob/1.2.1-1/Dockerfile)

## Configuration

This image runs [traefik][traefik] with monit. It is started with traefik user/group with 10001 uid/gid.

Besides, you can customize the configuration in several ways:

### Default Configuration

Traefic is installed with the default configuration and some parameters can be overrided with env variables:

- TRAEFIK_HTTP_PORT=8080								# http port > 1024 due to run as non privileged user
- TRAEFIK_HTTPS_ENABLE="false"							# "true" enables https and http endpoints. "Only" enables https endpoints and redirect http to https.
- TRAEFIK_HTTPS_PORT=8443								# https port > 1024 due to run as non privileged user
- TRAEFIK_ADMIN_PORT=8000								# admin port > 1024 due to run as non privileged user
- TRAEFIK_LOG_LEVEL="INFO"								# Log level
- TRAEFIK_LOG_FILE="/opt/traefik/log/traefik.log"}		# Log file. Redirected to docker stdout.
- TRAEFIK_ACCESS_FILE="/opt/traefik/log/access.log"}	# Access file. Redirected to docker stdout.
- TRAEFIK_SSL_PATH="/opt/traefik/certs"					# Path to search .key and .crt files
- TRAEFIK_ACME_ENABLE="false"							# Enable/disable traefik ACME feature
- TRAEFIK_ACME_EMAIL="test@traefik.io"					# Default email
- TRAEFIK_ACME_ONDEMAND="true"							# ACME ondemand parameter
- TRAEFIK_ACME_ONHOSTRULE="true"						# ACME OnHostRule parameter
- TRAEFIK_K8S_ENABLE="false"							# Enable/disable traefik K8S feature
- TRAEFIK_ACME_DNSPROVIDER="provider"						# Use DNS for ACME instead of HTTPS
- TRAEFIK_WEBUI_BASIC_AUTH							# Enable basic auth for the webui (use htpasswd to generate a string)
- TRAEFIK_WEBUI_DIGEST_AUTH							# Enable digest auth for the webui (use htdigest to generate a string)

### Custom Configuration

Traefik is installed under /opt/traefik and will write /opt/traefik/etc/traefik.toml temporarily. This is stored in the configured key-value store backend. Backend rules are generated from Rancher metadata.

Values in the KV store can be changed but defaults from traefik.toml should be modified there, or they may be overwritten. Labels on services will be used to generate backend rules.

See [here][traefik-docs] and [here][traefik-code] for details on Rancher backend.

### SSL Configuration

Added SSL configuration. Set TRAEFIK_HTTPS_ENABLE="< true || only >" to enable it. 

SSL certificates are copied to /opt/traefik/certs and imported into the KV store. You need to provide .key AND .crt files to that directory, in order traefik gets automatically configured with ssl.

If you put more that one key/crt files in the certs directory, traefik gets sni enabled and configured. You also could map you cert storage volume to traefik and mount it in $TRAEFIK_SSL_PATH value.

### Letsencrypt Configuration

If you enable SSL configuration, you could enable traefik letsencrypt support as well (ACME). To do it, set TRAEFIK_ACME_ENABLE="true".

You can also set TRAEFIK_ACME_DNSPROVIDER to your DNS provider (see [here][traefik-dns] for a supported list) and the appropriate other env vars to make traefik use DNS for letsencrypt instead of HTTPS.

## TODO

Additional KV backend options.

[alpine-monit]: https://github.com/rawmind0/alpine-monit/
[traefik]: https://github.com/containous/traefik
[rancher-traefik]: https://hub.docker.com/r/rawmind/rancher-traefik/
[rancher-example]: https://github.com/rawmind0/alpine-traefik/tree/master/rancher
[traefik-docs]: https://docs.traefik.io/toml/#rancher-backend
[traefik-code]: https://github.com/containous/traefik/blob/v1.2/provider/rancher.go
[traefik-dns]: https://docs.traefik.io/toml/#acme-lets-encrypt-configuration
