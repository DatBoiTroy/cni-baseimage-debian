# syntax=docker/dockerfile:1
FROM debian:bookworm-slim

ARG BUILD_DATE
ARG VERSION
ARG S6_OVERLAY_VERSION=3.2.0.0
ARG S6_OVERLAY_ARCH=x86_64
LABEL maintainer="tfreytag"

# Install base packages and those needed to extract S6 overlay.
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt install --no-install-recommends --no-install-suggests -y \
        ca-certificates\
        cron \
        curl \
        locales \
        logrotate \
        nano \
        tzdata \
        xz-utils && \
# Add S6 overlay.
    curl -fsSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz \
        -o s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf s6-overlay-noarch.tar.xz && \
    rm -f s6-overlay-noarch.tar.xz && \
    curl -fsSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz \
        -o s6-overlay-${S6_OVERLAY_ARCH}.tar.xz && \
    tar -C / -Jxpf s6-overlay-${S6_OVERLAY_ARCH}.tar.xz && \
    rm -f s6-overlay-${S6_OVERLAY_ARCH}.tar.xz && \
# Add S6 optional symlinks.
    curl -fsSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz \
        -o s6-overlay-symlinks-noarch.tar.xz && \
    tar -C / -Jxpf s6-overlay-symlinks-noarch.tar.xz && \
    rm -f s6-overlay-symlinks-noarch.tar.xz &&\
    curl -fsSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz \
        -o s6-overlay-symlinks-arch.tar.xz && \
    tar -C / -Jxpf s6-overlay-symlinks-arch.tar.xz && \
    rm -f s6-overlay-symlinks-arch.tar.xz && \
# Generate locales.
    sed -i 's/# \(en_US\.UTF-8 .*\)/\1/' /etc/locale.gen && \
    locale-gen && \
# Create non-root abc service user and default directories.
    groupadd --system --gid 911 abc && \
    useradd --system --gid abc --no-create-home --shell /bin/false --uid 911 abc && \
    mkdir -p \
        /app \
        /config/{log,logrotate} \
        /defaults && \
# Cleanup apt cache, temp files, and unneeded log files.
    apt autoremove --purge && \
    apt clean && \
    rm -rf \
        /tmp/* \
        /var/tmp/* \
        /var/cache/apt/archives/* \
        /var/lib/apt/lists/* \
        /var/log/* && \
# Configure custom location for logrotate status file.
    sed -i 's#/usr/sbin/logrotate /etc/logrotate.conf#/usr/sbin/logrotate /etc/logrotate.conf -s /config/logrotate/logrotate.status#g' \
        /etc/cron.daily/logrotate && \
# Add build information.
    printf "Version: ${VERSION}\nBuild-date: ${BUILD_DATE}\n" > /build_info

# Set environment variables.
ENV HOME=/root
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8 
ENV LC_ALL=en_US.UTF-8
ENV S6_VERBOSITY=1
ENV TZ=America/Detroit

# Add local root files.
COPY rootfs/ /

# Define config volume.
VOLUME /config

ENTRYPOINT ["/init"]