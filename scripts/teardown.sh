#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/phase2.env"

echo "============================================"
echo "  Tearing Down Phase 2 Resources"
echo "============================================"
echo ""

confluent environment use $ENV_ID

echo ">>> Stopping mirrors..."
confluent kafka cluster use $WEST_CLUSTER_ID
confluent api-key use $MANAGER_WEST_KEY --resource $WEST_CLUSTER_ID
confluent kafka mirror failover orders_east --link vj-aa-east-to-west 2>/dev/null || true

confluent kafka cluster use $EAST_CLUSTER_ID
confluent api-key use $MANAGER_EAST_KEY --resource $EAST_CLUSTER_ID
confluent kafka mirror failover orders_west --link vj-aa-west-to-east 2>/dev/null || true

sleep 5

echo ">>> Deleting cluster links..."
confluent kafka cluster use $WEST_CLUSTER_ID
confluent api-key use $SVC_LINK_WEST_KEY --resource $WEST_CLUSTER_ID
confluent kafka link delete vj-aa-east-to-west --force 2>/dev/null || true

confluent kafka cluster use $EAST_CLUSTER_ID
confluent api-key use $SVC_LINK_EAST_KEY --resource $EAST_CLUSTER_ID
confluent kafka link delete vj-aa-west-to-east --force 2>/dev/null || true

echo ">>> Deleting topics..."
confluent kafka cluster use $EAST_CLUSTER_ID
confluent api-key use $MANAGER_EAST_KEY --resource $EAST_CLUSTER_ID
confluent kafka topic delete orders_east --force 2>/dev/null || true

confluent kafka cluster use $WEST_CLUSTER_ID
confluent api-key use $MANAGER_WEST_KEY --resource $WEST_CLUSTER_ID
confluent kafka topic delete orders_west --force 2>/dev/null || true

echo ""
echo "Phase 2 resources deleted."
echo "Now on your Mac: cd phase1 && terraform destroy"
