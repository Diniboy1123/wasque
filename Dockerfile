# syntax=docker/dockerfile:1.4

FROM --platform=$BUILDPLATFORM alpine:latest AS debextract

RUN apk add --no-cache curl gnupg tar xz binutils

ARG WARP_VERSION

RUN curl -fsSL https://pkg.cloudflareclient.com/dists/noble/main/binary-amd64/Packages.gz | \
    gunzip | \
    awk '/Filename: / {print $2; exit}' | \
    xargs -I{} curl -o warp.deb https://pkg.cloudflareclient.com/{} && \
    mkdir -p /warp-extracted && \
    ar x warp.deb && \
    tar -C /warp-extracted -xf data.tar.gz && \
    find /warp-extracted/bin -type f -exec strip --strip-all {} \;

FROM --platform=$BUILDPLATFORM ghcr.io/void-linux/void-glibc:latest AS builder

COPY bind_redirect.c /bind_redirect.c

RUN xbps-install -Sy xbps gcc && \
    gcc -shared -fPIC -o /bind_redirect.so /bind_redirect.c -ldl

FROM ghcr.io/void-linux/void-glibc-busybox:latest AS fs

RUN xbps-install -Syu xbps dbus-libs nspr nss libgcc dbus shadow && \
    rm -rf /var/cache/xbps/* && \
    xbps-remove -y shadow

COPY --from=debextract /warp-extracted /tmp/warp-extracted
RUN \
  for entry in /tmp/warp-extracted/*; do \
    name=$(basename "$entry"); \
    if [ -d "/$name" ]; then \
      cp -a "$entry/." "/$name/"; \
    else \
      cp -a "$entry" "/"; \
    fi; \
  done

COPY --from=builder /bind_redirect.so /bind_redirect.so
COPY --chmod=755 entrypoint.sh /usr/bin/entrypoint.sh

FROM scratch

ARG WARP_VERSION
LABEL org.opencontainers.image.version=$WARP_VERSION

COPY --from=fs / /

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
