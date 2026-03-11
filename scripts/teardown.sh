#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/phase2.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found!"
  exit 1
fi

source "$ENV_FILE"

TOPIC_EAST="orders_east"
TOPIC_WEST="orders_west"

echo "============================================"
echo "  Tearing Down Phase 2 Resources"
echo "============================================"
echo ""

confluent environment use $ENV_ID

echo ">>> Stopping mirrors..."
confluent kafka cluster use $WEST_CLUSTER_ID
confluent api-key use $MANAGER_WEST_KEY --resource $WEST_CLUSTER_ID
confluent kafka mirror failover $TOPIC_EAST --link vj-aa-east-to-west 2>/dev/null || true

confluent kafka cluster use $EAST_CLUSTER_ID
confluent api-key use $MANAGER_EAST_KEY --resource $EAST_CLUSTER_ID
confluent kafka mirror failover $TOPIC_WEST --link vj-aa-west-to-east 2>/dev/null || true

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
confluent kafka topic delete $TOPIC_EAST --force 2>/dev/null || true

confluent kafka cluster use $WEST_CLUSTER_ID
confluent api-key use $MANAGER_WEST_KEY --resource $WEST_CLUSTER_ID
confluent kafka topic delete $TOPIC_WEST --force 2>/dev/null || true

echo ""
echo "Phase 2 resources deleted."
echo "Now on your Mac: cd phase1 && terraform destroy"
