#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/phase2.env"

echo "============================================"
echo "  Testing Bidirectional Replication"
echo "============================================"
echo ""

confluent environment use $ENV_ID

echo ">>> Producing 3 records to East (orders_east)..."
confluent kafka cluster use $EAST_CLUSTER_ID
confluent api-key use $MANAGER_EAST_KEY --resource $EAST_CLUSTER_ID
echo '{"order":1,"item":"widget","cost":10.00}
{"order":2,"item":"gadget","cost":25.00}
{"order":3,"item":"doohickey","cost":5.00}' | confluent kafka topic produce orders_east

echo ""
echo ">>> Waiting 5 seconds for replication..."
sleep 5

echo ""
echo ">>> Consuming mirror from West (Ctrl+C to stop)..."
confluent kafka cluster use $WEST_CLUSTER_ID
confluent api-key use $MANAGER_WEST_KEY --resource $WEST_CLUSTER_ID
confluent kafka topic consume orders_east --from-beginning
