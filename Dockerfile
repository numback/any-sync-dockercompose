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

# Copy tools (these are known to exist)
COPY --from=tools-src /usr/bin/any-sync-netcheck /usr/local/bin/
COPY --from=tools-src /usr/bin/anyconf /usr/local/bin/

# Copy ALL files from each image to /tmp/src-*
# Then use RUN to find and copy the correct binaries
COPY --from=coord-src / /tmp/src-coord/
COPY --from=node-src / /tmp/src-node/
COPY --from=filenode-src / /tmp/src-filenode/
COPY --from=consensus-src / /tmp/src-consensus/

# Find and install binaries from each source
RUN set -ex; \
    # Coordinator: find any-sync-coordinator or server binary
    if [ -f /tmp/src-coord/usr/local/bin/any-sync-coordinator ]; then \
        cp /tmp/src-coord/usr/local/bin/any-sync-coordinator /usr/local/bin/any-sync-coordinator; \
    elif [ -f /tmp/src-coord/any-sync-coordinator ]; then \
        cp /tmp/src-coord/any-sync-coordinator /usr/local/bin/any-sync-coordinator; \
    elif [ -f /tmp/src-coord/server ]; then \
        cp /tmp/src-coord/server /usr/local/bin/any-sync-coordinator; \
    elif [ -f /tmp/src-coord/usr/bin/any-sync-coordinator ]; then \
        cp /tmp/src-coord/usr/bin/any-sync-coordinator /usr/local/bin/any-sync-coordinator; \
    else \
        echo "WARN: coordinator binary not found, searching..."; \
        find /tmp/src-coord/ -type f -executable -name "*coordinator*" -o -name "server" | head -1 | xargs -I{} cp {} /usr/local/bin/any-sync-coordinator; \
    fi; \
    # Node: find any-sync-node or server binary
    if [ -f /tmp/src-node/usr/local/bin/any-sync-node ]; then \
        cp /tmp/src-node/usr/local/bin/any-sync-node /usr/local/bin/any-sync-node; \
    elif [ -f /tmp/src-node/any-sync-node ]; then \
        cp /tmp/src-node/any-sync-node /usr/local/bin/any-sync-node; \
    elif [ -f /tmp/src-node/server ]; then \
        cp /tmp/src-node/server /usr/local/bin/any-sync-node; \
    elif [ -f /tmp/src-node/usr/bin/any-sync-node ]; then \
        cp /tmp/src-node/usr/bin/any-sync-node /usr/local/bin/any-sync-node; \
    else \
        echo "WARN: node binary not found, searching..."; \
        find /tmp/src-node/ -type f -executable -name "*node*" -o -name "server" | head -1 | xargs -I{} cp {} /usr/local/bin/any-sync-node; \
    fi; \
    # Filenode: find any-sync-filenode or server binary
    if [ -f /tmp/src-filenode/usr/local/bin/any-sync-filenode ]; then \
        cp /tmp/src-filenode/usr/local/bin/any-sync-filenode /usr/local/bin/any-sync-filenode; \
    elif [ -f /tmp/src-filenode/any-sync-filenode ]; then \
        cp /tmp/src-filenode/any-sync-filenode /usr/local/bin/any-sync-filenode; \
    elif [ -f /tmp/src-filenode/server ]; then \
        cp /tmp/src-filenode/server /usr/local/bin/any-sync-filenode; \
    elif [ -f /tmp/src-filenode/usr/bin/any-sync-filenode ]; then \
        cp /tmp/src-filenode/usr/bin/any-sync-filenode /usr/local/bin/any-sync-filenode; \
    else \
        echo "WARN: filenode binary not found, searching..."; \
        find /tmp/src-filenode/ -type f -executable -name "*filenode*" -o -name "server" | head -1 | xargs -I{} cp {} /usr/local/bin/any-sync-filenode; \
    fi; \
    # Consensusnode: find any-sync-consensusnode or server binary
    if [ -f /tmp/src-consensus/usr/local/bin/any-sync-consensusnode ]; then \
        cp /tmp/src-consensus/usr/local/bin/any-sync-consensusnode /usr/local/bin/any-sync-consensusnode; \
    elif [ -f /tmp/src-consensus/any-sync-consensusnode ]; then \
        cp /tmp/src-consensus/any-sync-consensusnode /usr/local/bin/any-sync-consensusnode; \
    elif [ -f /tmp/src-consensus/server ]; then \
        cp /tmp/src-consensus/server /usr/local/bin/any-sync-consensusnode; \
    elif [ -f /tmp/src-consensus/usr/bin/any-sync-consensusnode ]; then \
        cp /tmp/src-consensus/usr/bin/any-sync-consensusnode /usr/local/bin/any-sync-consensusnode; \
    else \
        echo "WARN: consensusnode binary not found, searching..."; \
        find /tmp/src-consensus/ -type f -executable -name "*consensus*" -o -name "server" | head -1 | xargs -I{} cp {} /usr/local/bin/any-sync-consensusnode; \
    fi; \
    # Make all binaries executable
    chmod +x /usr/local/bin/any-sync-coordinator /usr/local/bin/any-sync-node /usr/local/bin/any-sync-filenode /usr/local/bin/any-sync-consensusnode 2>/dev/null || true; \
    # Cleanup temp files
    rm -rf /tmp/src-coord /tmp/src-node /tmp/src-filenode /tmp/src-consensus; \
    echo "Done installing binaries"

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
