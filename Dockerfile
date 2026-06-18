FROM ubuntu:22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    supervisor \
    python3 \
    python3-yaml \
    perl \
    jq \
    && curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
       -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq \
    && rm -rf /var/lib/apt/lists/*

# --- Stage: copy any-sync binaries from official images ---
FROM ghcr.io/anyproto/any-sync-tools:latest AS tools-src
FROM ghcr.io/anyproto/any-sync-coordinator:v0.9.1 AS coord-src
FROM ghcr.io/anyproto/any-sync-node:v0.11.1 AS node-src
FROM ghcr.io/anyproto/any-sync-filenode:v0.11.1 AS filenode-src
FROM ghcr.io/anyproto/any-sync-consensusnode:v0.7.2 AS consensus-src

# --- Final stage ---
FROM base

# Copy tools
COPY --from=tools-src /usr/bin/any-sync-netcheck /usr/local/bin/
COPY --from=tools-src /usr/bin/anyconf /usr/local/bin/

# Copy service binaries (try multiple paths)
COPY --from=coord-src /any-sync-coordinator /usr/local/bin/any-sync-coordinator 2>/dev/null || true
COPY --from=coord-src /server /usr/local/bin/any-sync-coordinator 2>/dev/null || true
COPY --from=node-src /any-sync-node /usr/local/bin/any-sync-node 2>/dev/null || true
COPY --from=node-src /server /usr/local/bin/any-sync-node 2>/dev/null || true
COPY --from=filenode-src /any-sync-filenode /usr/local/bin/any-sync-filenode 2>/dev/null || true
COPY --from=filenode-src /server /usr/local/bin/any-sync-filenode 2>/dev/null || true
COPY --from=consensus-src /any-sync-consensusnode /usr/local/bin/any-sync-consensusnode 2>/dev/null || true
COPY --from=consensus-src /server /usr/local/bin/any-sync-consensusnode 2>/dev/null || true

# Ensure binaries are executable
RUN chmod +x /usr/local/bin/any-sync-* 2>/dev/null || true

# MongoDB 7.0
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc \
    | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg \
    && echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" \
    > /etc/apt/sources.list.d/mongodb-org-7.0.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends mongodb-org \
    && rm -rf /var/lib/apt/lists/*

# Redis
RUN apt-get update \
    && apt-get install -y --no-install-recommends redis-server \
    && rm -rf /var/lib/apt/lists/*

# MinIO server + client
RUN curl -fsSL https://dl.min.io/server/minio/release/linux-amd64/minio \
    -o /usr/local/bin/minio && chmod +x /usr/local/bin/minio \
    && curl -fsSL https://dl.min.io/client/mc/release/linux-amd64/mc \
    -o /usr/local/bin/mc && chmod +x /usr/local/bin/mc

RUN mkdir -p /data/db /data/redis /data/minio /storage /anyStorage /networkStore /etc/any-sync /scripts

COPY entrypoint.sh /scripts/entrypoint.sh
RUN chmod +x /scripts/entrypoint.sh

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker-generateconfig /scripts/docker-generateconfig

EXPOSE 1001 1002 1003 1004 1005 1006 \
       1011/udp 1012/udp 1013/udp 1014/udp 1015/udp 1016/udp \
       27001 6379 9000 9001

VOLUME ["/data"]

ENTRYPOINT ["/scripts/entrypoint.sh"]
