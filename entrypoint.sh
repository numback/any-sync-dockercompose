#!/bin/bash
set -e

DATA_DIR="/data"
ETC_DIR="${DATA_DIR}/etc"
STORAGE_DIR="${DATA_DIR}/storage"
GENERATED_FLAG="${DATA_DIR}/.initialized"

echo "============================================"
echo "  AnyType Self-Hosted Sync Network"
echo "  All-in-One for ZimaOS"
echo "============================================"

# --- Load environment variables ---
if [ -f /scripts/.env ]; then
    set -a
    source /scripts/.env
    set +a
fi

# Apply defaults
EXTERNAL_LISTEN_HOSTS="${EXTERNAL_LISTEN_HOSTS:-127.0.0.1}"
MONGO_1_PORT="${MONGO_1_PORT:-27001}"
REDIS_PORT="${REDIS_PORT:-6379}"
MINIO_PORT="${MINIO_PORT:-9000}"
MINIO_WEB_PORT="${MINIO_WEB_PORT:-9001}"
MINIO_BUCKET="${MINIO_BUCKET:-minio-bucket}"
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-minio_access_key}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-minio_secret_key}"

# --- Phase 0: Start MongoDB in background for init ---
echo "[init] Starting MongoDB for configuration..."
mkdir -p /data/db
mongod --replSet rs0 --port "${MONGO_1_PORT}" --dbpath /data/db --bind_ip 127.0.0.1 \
    --fork --logpath /tmp/mongod-init.log

echo "[init] Waiting for MongoDB..."
until mongosh --port "${MONGO_1_PORT}" --quiet --eval "db.runCommand({ping:1})" >/dev/null 2>&1; do
    sleep 1
done
echo "[init] MongoDB is ready."

# --- Phase 0.5: Init replica set ---
echo "[init] Initializing MongoDB replica set..."
mongosh --port "${MONGO_1_PORT}" --quiet --eval "
try { rs.initiate({_id:'rs0', members:[{_id:0, host:'127.0.0.1:${MONGO_1_PORT}'}]}) } catch(e) { rs.status().ok }
" || true

# --- Phase 1: Generate configs if not initialized ---
if [ ! -f "${GENERATED_FLAG}" ]; then
    echo "[init] First run detected. Generating network configuration..."
    mkdir -p "${STORAGE_DIR}/docker-generateconfig" "${ETC_DIR}"

    cd /scripts

    # Create network
    if [ ! -s "${STORAGE_DIR}/docker-generateconfig/.networkId" ]; then
        echo "[init] Creating network..."
        anyconf create-network
        grep '^networkId:' "${STORAGE_DIR}/docker-generateconfig/nodes.yml" | awk '{print $NF}' \
            > "${STORAGE_DIR}/docker-generateconfig/.networkId"
        yq '.account.signingKey' "${STORAGE_DIR}/docker-generateconfig/account.yml" \
            > "${STORAGE_DIR}/docker-generateconfig/.networkSigningKey"
    fi

    NETWORK_ID=$(cat "${STORAGE_DIR}/docker-generateconfig/.networkId")
    NETWORK_SIGNING_KEY=$(cat "${STORAGE_DIR}/docker-generateconfig/.networkSigningKey")

    # Generate node configs
    if [ ! -f "${STORAGE_DIR}/docker-generateconfig/account0.yml" ]; then
        echo "[init] Generating node configurations..."
        anyconf generate-nodes \
            --t tree --t tree --t tree \
            --t coordinator --t file --t consensus \
            --addresses "any-sync-node-1:${ANY_SYNC_NODE_1_PORT:-1001}" \
            --addresses "any-sync-node-2:${ANY_SYNC_NODE_2_PORT:-1002}" \
            --addresses "any-sync-node-3:${ANY_SYNC_NODE_3_PORT:-1003}" \
            --addresses "any-sync-coordinator:${ANY_SYNC_COORDINATOR_PORT:-1004}" \
            --addresses "any-sync-filenode:${ANY_SYNC_FILENODE_PORT:-1005}" \
            --addresses "any-sync-consensusnode:${ANY_SYNC_CONSENSUSNODE_PORT:-1006}"
    fi

    yq --indent 2 --inplace 'del(.creationTime)' "${STORAGE_DIR}/docker-generateconfig/nodes.yml"
    yq --indent 2 --inplace ".networkId |= \"${NETWORK_ID}\"" "${STORAGE_DIR}/docker-generateconfig/nodes.yml"
    yq --indent 2 --inplace ".account.signingKey |= \"${NETWORK_SIGNING_KEY}\"" "${STORAGE_DIR}/docker-generateconfig/account3.yml"
    yq --indent 2 --inplace ".account.signingKey |= \"${NETWORK_SIGNING_KEY}\"" "${STORAGE_DIR}/docker-generateconfig/account5.yml"

    # --- Phase 2: Process configs ---
    echo "[init] Processing configuration files..."

    for NODE_TYPE in node-1 node-2 node-3 filenode coordinator consensusnode; do
        mkdir -p "${ETC_DIR}/any-sync-${NODE_TYPE}"
    done
    mkdir -p "${ETC_DIR}/.aws"

    # Set listen IPs
    python3 /scripts/docker-generateconfig/setListenIp.py \
        "${STORAGE_DIR}/docker-generateconfig/nodes.yml" \
        "${STORAGE_DIR}/docker-generateconfig/nodesProcessed.yml"

    # Generate client.yml
    cp "${STORAGE_DIR}/docker-generateconfig/nodesProcessed.yml" "${ETC_DIR}/client.yml"

    # Generate network file
    yq eval '. as $item | {"network": $item}' --indent 2 \
        "${STORAGE_DIR}/docker-generateconfig/nodesProcessed.yml" > "${STORAGE_DIR}/docker-generateconfig/network.yml"

    # Generate node configs
    for i in 0 1 2; do
        NODE_NUM=$((i+1))
        cat \
            "${STORAGE_DIR}/docker-generateconfig/network.yml" \
            /scripts/docker-generateconfig/etc/common.yml \
            "${STORAGE_DIR}/docker-generateconfig/account${i}.yml" \
            /scripts/docker-generateconfig/etc/node-${NODE_NUM}.yml \
            > "${ETC_DIR}/any-sync-node-${NODE_NUM}/config.yml"
    done

    # Generate coordinator, filenode, consensusnode configs
    declare -A SERVICE_ACCOUNTS=([coordinator]=3 [filenode]=4 [consensusnode]=5)
    for SERVICE in coordinator filenode consensusnode; do
        cat \
            "${STORAGE_DIR}/docker-generateconfig/network.yml" \
            /scripts/docker-generateconfig/etc/common.yml \
            "${STORAGE_DIR}/docker-generateconfig/account${SERVICE_ACCOUNTS[$SERVICE]}.yml" \
            /scripts/docker-generateconfig/etc/${SERVICE}.yml \
            > "${ETC_DIR}/any-sync-${SERVICE}/config.yml"
    done

    cp "${STORAGE_DIR}/docker-generateconfig/nodesProcessed.yml" "${ETC_DIR}/any-sync-coordinator/network.yml"

    # AWS credentials
    cat > "${ETC_DIR}/.aws/credentials" <<AWSEOF
[default]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}
AWSEOF

    # Replace env variable placeholders in configs
    for PLACEHOLDER in $(perl -ne 'print "$1\n" if /^([A-z0-9_-]+)=/' /scripts/.env); do
        VALUE="${!PLACEHOLDER}"
        if [ -n "$VALUE" ]; then
            find "${ETC_DIR}" -name "*.yml" -exec perl -i -pe "s|%${PLACEHOLDER}%|${VALUE}|g" {} +
            perl -i -pe "s|%${PLACEHOLDER}%|${VALUE}|g" "${ETC_DIR}/.aws/credentials"
            perl -i -pe "s|%${PLACEHOLDER}%|${VALUE}|g" "${STORAGE_DIR}/docker-generateconfig/network.yml"
        fi
    done

    # Fix indent
    find "${ETC_DIR}" -name "*.yml" -exec yq --inplace --indent=2 {} +

    touch "${GENERATED_FLAG}"
    echo "[init] Configuration generated successfully!"
else
    echo "[init] Configuration already exists, skipping generation."
fi

# --- Stop init MongoDB ---
echo "[init] Stopping init MongoDB..."
mongod --shutdown --dbpath /data/db --port "${MONGO_1_PORT}" 2>/dev/null || true
sleep 2

# --- Export all env vars for supervisord ---
export EXTERNAL_LISTEN_HOSTS MONGO_1_PORT MONGO_CONNECT MONGO_REPLICA_SET \
    REDIS_HOST REDIS_PORT REDIS_URL REDIS_MAXMEMORY \
    AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY MINIO_BUCKET MINIO_PORT MINIO_WEB_PORT \
    ANY_SYNC_NODE_1_PORT ANY_SYNC_NODE_2_PORT ANY_SYNC_NODE_3_PORT \
    ANY_SYNC_COORDINATOR_PORT ANY_SYNC_FILENODE_PORT ANY_SYNC_CONSENSUSNODE_PORT

# --- Start all services via supervisord ---
echo "[init] Starting all services..."
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n
