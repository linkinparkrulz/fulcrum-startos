#!/bin/bash

set -e

# Get config
BITCOIND_TYPE=$(yq e '.bitcoind.type' /data/start9/config.yaml)

# Set RPC port based on bitcoind type
if [ "$BITCOIND_TYPE" = "bitcoind-testnet" ]; then
    export BITCOIND_RPC_PORT=48332
    export BITCOIND_HOST="bitcoind-testnet.embassy"
else
    export BITCOIND_RPC_PORT=8332
    export BITCOIND_HOST="bitcoind.embassy"
fi

if [ ! -e "$SSL_CERTFILE" ] || [ ! -e "$SSL_KEYFILE" ] ; then
  openssl req -newkey rsa:2048 -sha256 -nodes -x509 -days 365 -subj "/O=Fulcrum" -keyout "$SSL_KEYFILE" -out "$SSL_CERTFILE"
fi

if [ "$1" = "Fulcrum" ] ; then
  set -- "$@" -D "$DATA_DIR" -c "$SSL_CERTFILE" -k "$SSL_KEYFILE"
fi

# ignore database files for backups
echo 'fulc2_db/' > /data/.backupignore

TOR_ADDRESS=$(yq '.electrum-tor-address' /data/start9/config.yaml)

cat << EOF > /data/start9/stats.yaml
---
version: 2
data:
  Quick Connect URL:
    type: string
    value: $TOR_ADDRESS:50001:t
    description: For scanning into wallets such as BlueWallet
    copyable: true
    qr: true
    masked: true
  Hostname:
    type: string
    value: $TOR_ADDRESS
    description: Hostname to input into wallet software such as Sparrow.
    copyable: true
    qr: false
    masked: true
  Port:
    type: string
    value: "50001"
    description: Port to input into wallet software such as Sparrow.
    copyable: true
    qr: false
    masked: false
EOF

configurator

# Check if this is an upgrade from Fulcrum 1.x to 2.0 and add --db-upgrade flag if needed
echo "DEBUG: Checking for database upgrade..."
echo "DEBUG: /data/db exists: $([ -d "/data/db" ] && echo "YES" || echo "NO")"
echo "DEBUG: /data/headers exists: $([ -f "/data/headers" ] && echo "YES" || echo "NO")"
echo "DEBUG: /data/txnum2txhash exists: $([ -f "/data/txnum2txhash" ] && echo "YES" || echo "NO")"
echo "DEBUG: Marker file exists: $([ -f "/data/.fulcrum-2.0-upgraded" ] && echo "YES" || echo "NO")"
ls -la /data/ || echo "DEBUG: /data directory listing failed"

FULCRUM_ARGS=""
# Check for Fulcrum 1.x database files (headers, txnum2txhash, etc.) in /data root
if ([ -f "/data/headers" ] || [ -f "/data/txnum2txhash" ] || [ -d "/data/db" ]) && [ ! -f "/data/.fulcrum-2.0-upgraded" ]; then
    echo "DEBUG: Detected existing Fulcrum 1.x database files. Adding --db-upgrade flag for one-time upgrade to 2.0 format."
    FULCRUM_ARGS="--db-upgrade"
    # Create marker file to prevent running upgrade again
    touch /data/.fulcrum-2.0-upgraded
    echo "DEBUG: Created marker file /data/.fulcrum-2.0-upgraded"
else
    echo "DEBUG: No database upgrade needed"
fi

# Execute Fulcrum with proper argument order
echo "DEBUG: FULCRUM_ARGS='$FULCRUM_ARGS'"

# Send all stdout/stderr through tee once, to both console and log
exec > >(tee -a /data/fulcrum.log) 2>&1

if [ -n "$FULCRUM_ARGS" ]; then
    echo "DEBUG: Executing: Fulcrum $FULCRUM_ARGS /data/fulcrum.conf"
    exec tini -p SIGTERM -- Fulcrum $FULCRUM_ARGS /data/fulcrum.conf
else
    echo "DEBUG: Executing: Fulcrum /data/fulcrum.conf"
    exec tini -p SIGTERM -- Fulcrum /data/fulcrum.conf
fi
