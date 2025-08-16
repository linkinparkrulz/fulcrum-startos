#!/bin/bash

DURATION=$(</dev/stdin)
if ((DURATION <= 9000)); then
   exit 60
fi

set -e

btc_type=$(yq '.bitcoind.type' /data/start9/config.yaml)
btc_host="${btc_type}.embassy"

if [ "$btc_host" = "bitcoind-testnet.embassy" ]; then
   btc_port=48332
else
   btc_port=8332
fi

btc_url="http://$btc_host:$btc_port"

user=$(yq '.bitcoind.username' /data/start9/config.yaml)
pass=$(yq '.bitcoind.password' /data/start9/config.yaml)
credentials="$user:$pass"
rpc_method='{"jsonrpc": "1.0", "method": "getblockchaininfo"}'
req_headers='content-type: text/plain;'

# Get blockchain info from the bitcoin rpc
if ! chain_info=$(curl -sS --user "$credentials" --data-binary "$rpc_method" -H "$req_headers" "$btc_url"/ 2>&1); then
   echo "Error contacting Bitcoin RPC: $chain_info" >&2
   exit 61
fi

resp_error=$(echo "$chain_info" | yq '.error' -)
if [ "$resp_error" != "null" ]; then
   # request ok, but is an error; for example:'{"result":null,"error":{"code":-28,"message":"Verifying blocks…"}'

   err_message=$(echo "$resp_error" | yq '.message' -)
   echo "Bitcoin RPC returned error: $err_message" >&2
   exit 61
fi

block_count=$(echo "$chain_info" | yq '.result.blocks' -)
ibd=$(echo "$chain_info" | yq '.result.initialblockdownload' -)

if [ "$ibd" != "false" ]; then
   header_count=$(echo "$chain_info" | yq '.result.headers' -)

   echo -n "Bitcoin blockchain is not fully synced yet: $block_count of $header_count blocks" >&2
   echo " ($((block_count * 100 / header_count))%)" >&2
   exit 61
fi

json_version='{"jsonrpc": "2.0", "method": "server.version", "id": 0}'
if echo "$json_version" | netcat -w 1 127.0.0.1 50001 &>/dev/null; then
   # Index is synced to tip
   exit 0
fi

fulcrum_log="$(tail -n1 /data/fulcrum.log)"
if [ -z "$fulcrum_log" ]; then
   echo "Fulcrum RPC is not responding." >&2
   exit 61
fi

# echo log message, removing timestamp and <Controller>
echo "${fulcrum_log#*> }" >&2
exit 61
