FROM golang:1.22.4-bookworm as builder
WORKDIR /app
COPY . ./
# This is where one could build the application code as well.


FROM debian:bookworm as tailscale
WORKDIR /app
COPY . ./
ENV TSFILE=tailscale_1.16.2_amd64.tgz
RUN apt-get update && apt-get install sudo curl
RUN sudo mkdir -p --mode=0755 /usr/share/keyrings
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
RUN sudo apt-get update && sudo apt-get install tailscale
COPY . ./

FROM debian:bookworm
RUN apt-get update && apt-get -y install ca-certificates openssh-server sudo && rm -rf /var/cache/apk/*

# Copy binary to production image
COPY --from=builder /app/start.sh /app/start.sh
COPY --from=builder /app/my-app /app/my-app
COPY --from=tailscale /app/tailscaled /app/tailscaled
COPY --from=tailscale /app/tailscale /app/tailscale

RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale


# Run on container startup.
CMD ["/app/start.sh"]
