# ThingsPanel notification plugin: SMTP email

SMTP email only. Validation is side-effect free; server/port and TLS mode are operator-owned. Ambiguous SMTP DATA outcomes are unknown and never retried.

This is an independent Go module for the frozen ThingsPanel notification plugin HTTP v1 contract. It includes the provider adapter, executable, tests, and a source snapshot of the portable SDK so it builds without Encore/Core imports or external Go dependencies. SDK source is maintained at [thingspanel-notification-plugin-sdk](https://github.com/ThingsPanel/thingspanel-notification-plugin-sdk); compare snapshots when upgrading.

## Build and test

```sh
GOPROXY=off GOSUMDB=off go test ./...
GOPROXY=off GOSUMDB=off go vet ./...
GOPROXY=off GOSUMDB=off go build ./cmd/plugin
```

Tests use local fixtures only. Running the executable does not authorize or perform a real provider send. Do not put credentials in source control or logs. `accepted` means provider submission acceptance, not delivery; uncertain outcomes are not automatically retried.

The module path is `github.com/ThingsPanel/thingspanel-notification-smtp`. This project is licensed under Apache-2.0.

## Run the container locally

The checked-in Compose example builds the image locally and binds its port to loopback only. It does not pull or publish a registry image.

```sh
cp .env.example .env
chmod 600 .env
```

Edit the private `.env` file before starting and replace the token with an operator-generated random value. An empty `NOTIFICATION_SMTP_ALLOWED_SERVERS` is a supported preinstalled state: the plugin serves its manifest and health check, validates with `configuration_required`, and rejects every send with `configuration_required` before any SMTP network call. To enable email, an operator must add exact, resolvable `host:port` entries that they approve; wildcards are not accepted. Keep `.env` outside Git. Do not pass either `NOTIFICATION_PLUGIN_TOKEN` or SMTP passwords through Docker build arguments, Dockerfile `ARG`/`ENV`, image layers, or checked-in Compose values. The plugin token belongs only in runtime configuration.

```sh
docker compose -f compose.yaml build
docker compose -f compose.yaml up -d
docker compose -f compose.yaml logs smtp-plugin
docker compose -f compose.yaml down
```

The executable's actual environment variables are `NOTIFICATION_PLUGIN_TOKEN`, `NOTIFICATION_SMTP_ALLOWED_SERVERS`, optional `NOTIFICATION_SMTP_ALLOWED_CIDRS`, optional `NOTIFICATION_PLUGIN_UI_ORIGINS`, and `NOTIFICATION_PLUGIN_LISTEN`. The executable defaults to `127.0.0.1:5005`; Compose explicitly changes this to `0.0.0.0:5005` inside the container and exposes it only at host `127.0.0.1:5005`. Startup validates and resolves configured exact allowlist entries but does not connect to SMTP or send mail. With an empty allowlist, health and manifest remain available while validation/send fail closed without outbound connections. TLS verification uses the runtime CA bundle.

This Compose setup is for local build and operation checks. For a Core deployment, place the plugin behind the platform's private network and trusted TLS origin. A platform administrator must opt in to plugin registration and configure a tenant-scoped SMTP account. Installing or starting this container does not create a tenant grant/account, configure SMTP credentials, or send a message. SMTP passwords stay in the platform's encrypted tenant account configuration and are supplied per validate/send request; they do not belong in this plugin `.env` file. A successful `accepted` result means SMTP submission acceptance, not mailbox delivery.

The example uses `thingspanel/notification-smtp:local`, a local-only image name. This repository does not publish a registry image; operators may build locally or arrange their own registry release process.
