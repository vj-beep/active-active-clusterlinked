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

echo ">>> Stopping mirrors..."
confluent kafka mirror failover $TOPIC_EAST \
  --link vj-aa-east-to-west \
  --environment $ENV_ID \
  --cluster $WEST_CLUSTER_ID \
  --api-key $MANAGER_WEST_KEY \
  --api-secret $MANAGER_WEST_SECRET 2>/dev/null || true

confluent kafka mirror failover $TOPIC_WEST \
  --link vj-aa-west-to-east \
  --environment $ENV_ID \
  --cluster $EAST_CLUSTER_ID \
  --api-key $MANAGER_EAST_KEY \
  --api-secret $MANAGER_EAST_SECRET 2>/dev/null || true

sleep 5

echo ">>> Deleting cluster links..."
confluent kafka link delete vj-aa-east-to-west \
  --environment $ENV_ID \
  --cluster $WEST_CLUSTER_ID \
  --api-key $SVC_LINK_WEST_KEY \
  --api-secret $SVC_LINK_WEST_SECRET \
  --force 2>/dev/null || true

confluent kafka link delete vj-aa-west-to-east \
  --environment $ENV_ID \
  --cluster $EAST_CLUSTER_ID \
  --api-key $SVC_LINK_EAST_KEY \
  --api-secret $SVC_LINK_EAST_SECRET \
  --force 2>/dev/null || true

echo ">>> Deleting topics..."
confluent kafka topic delete $TOPIC_EAST \
  --environment $ENV_ID \
  --cluster $EAST_CLUSTER_ID \
  --api-key $MANAGER_EAST_KEY \
  --api-secret $MANAGER_EAST_SECRET \
  --force 2>/dev/null || true

confluent kafka topic delete $TOPIC_WEST \
  --environment $ENV_ID \
  --cluster $WEST_CLUSTER_ID \
  --api-key $MANAGER_WEST_KEY \
  --api-secret $MANAGER_WEST_SECRET \
  --force 2>/dev/null || true

echo ""
echo "Phase 2 resources deleted."
echo "Now on your Mac: cd phase1 && terraform destroy"