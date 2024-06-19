FROM golang:1.16.2-alpine3.13 as builder
WORKDIR /app
COPY . ./
# This is where one could build the application code as well.


FROM alpine:latest as tailscale
WORKDIR /app
COPY . ./
ENV TSFILE=tailscale_1.16.2_amd64.tgz
RUN apk update && apk add curl
RUN apk update && apk fetch gnupg && apk add gnupg && gpg --keyserver https://pkgs.tailscale.com/stable/ubuntu/xenial.asc
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/xenial.list | tee /etc/apt/sources.list.d/tailscale.list
RUN apk update && apk add tailscale
COPY . ./


FROM alpine:latest
RUN apk update && apk add ca-certificates openssh sudo && rm -rf /var/cache/apk/*

# Copy binary to production image
COPY --from=builder /app/start.sh /app/start.sh
COPY --from=builder /app/my-app /app/my-app
COPY --from=tailscale /app/tailscaled /app/tailscaled
COPY --from=tailscale /app/tailscale /app/tailscale

RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale


# Run on container startup.
CMD ["/app/start.sh"]
