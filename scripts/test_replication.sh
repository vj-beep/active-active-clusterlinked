#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/phase2.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found!"
  exit 1
fi

source "$ENV_FILE"

TOPIC="orders_east"

echo "============================================"
echo "  Testing Bidirectional Replication"
echo "============================================"
echo ""

confluent environment use $ENV_ID

echo ">>> Producing 3 records to East cluster ($TOPIC)..."
confluent kafka cluster use $EAST_CLUSTER_ID
confluent api-key use $MANAGER_EAST_KEY --resource $EAST_CLUSTER_ID
echo '{"order":1,"item":"widget","cost":10.00}
{"order":2,"item":"gadget","cost":25.00}
{"order":3,"item":"doohickey","cost":5.00}' | confluent kafka topic produce $TOPIC

echo ""
echo ">>> Waiting 5 seconds for replication..."
sleep 5

echo ""
echo ">>> Consuming from West cluster mirror (Ctrl+C to stop)..."
confluent kafka cluster use $WEST_CLUSTER_ID
confluent api-key use $MANAGER_WEST_KEY --resource $WEST_CLUSTER_ID
confluent kafka topic consume $TOPIC --from-beginning
