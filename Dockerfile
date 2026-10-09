FROM golang:1.23-bookworm AS build

WORKDIR /src
ENV CGO_ENABLED=0 GOOS=linux GOPROXY=off GOSUMDB=off

COPY go.mod ./
COPY sdk ./sdk
COPY smtp ./smtp
COPY cmd/plugin ./cmd/plugin

RUN go build -trimpath -ldflags="-s -w" -o /out/notification-smtp ./cmd/plugin \
    && test -s /etc/ssl/certs/ca-certificates.crt

FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=build --chown=nonroot:nonroot /out/notification-smtp /notification-smtp
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
EXPOSE 5005
USER nonroot:nonroot
ENTRYPOINT ["/notification-smtp"]
