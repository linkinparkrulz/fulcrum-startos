#!/bin/bash

DURATION=$(</dev/stdin)
if ((DURATION <= 9000)); then
   exit 60
fi

set -e

# Check if Fulcrum is responding to Electrum protocol
json_version='{"jsonrpc": "2.0", "method": "server.version", "id": 0}'
if echo "$json_version" | netcat -w 1 127.0.0.1 50001 &>/dev/null; then
   # Check the most recent log line to see if Fulcrum reports being up-to-date
   fulcrum_log="$(tail -n10 /data/fulcrum.log | grep -E "(up-to-date|Block height)" | tail -n1)"
   
   if [ -n "$fulcrum_log" ] && echo "$fulcrum_log" | grep -q "up-to-date"; then
      # Fulcrum is synced and up-to-date
      exit 0
   elif [ -n "$fulcrum_log" ] && echo "$fulcrum_log" | grep -q "Block height"; then
      # Fulcrum is processing blocks (likely synced)
      exit 0
   else
      echo "Fulcrum is running but sync status unclear" >&2
      exit 61
   fi
fi

# If we get here, Fulcrum is not responding
fulcrum_log="$(tail -n1 /data/fulcrum.log)"
if [ -z "$fulcrum_log" ]; then
   echo "Fulcrum RPC is not responding." >&2
   exit 61
fi

# echo log message, removing timestamp and <Controller>
echo "${fulcrum_log#*> }" >&2
exit 61
