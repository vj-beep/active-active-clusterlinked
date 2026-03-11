#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/phase2.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found!"
  echo "Generate it from phase1:"
  echo "  cd phase1"
  echo "  terraform output -raw phase2_env > ../scripts/phase2.env"
  exit 1
fi

source "$ENV_FILE"

TOPIC_EAST="orders_east"
TOPIC_WEST="orders_west"
PARTITIONS=3

echo "============================================"
echo "  Phase 2 - Topics, Cluster Links, Mirrors"
echo "============================================"
echo ""
echo "Environment:  $ENV_ID"
echo "East Cluster: $EAST_CLUSTER_ID"
echo "West Cluster: $WEST_CLUSTER_ID"
echo ""

echo ">>> Step 0: Configuring Confluent CLI..."
confluent environment use $ENV_ID
confluent api-key store $MANAGER_EAST_KEY "$MANAGER_EAST_SECRET" --resource $EAST_CLUSTER_ID --force
confluent api-key store $MANAGER_WEST_KEY "$MANAGER_WEST_SECRET" --resource $WEST_CLUSTER_ID --force
confluent api-key store $SVC_LINK_EAST_KEY "$SVC_LINK_EAST_SECRET" --resource $EAST_CLUSTER_ID --force
confluent api-key store $SVC_LINK_WEST_KEY "$SVC_LINK_WEST_SECRET" --resource $WEST_CLUSTER_ID --force
echo "  API keys stored."
echo ""

echo ">>> Step 1: Creating topics..."
confluent kafka cluster use $EAST_CLUSTER_ID
confluent api-key use $MANAGER_EAST_KEY --resource $EAST_CLUSTER_ID
confluent kafka topic create $TOPIC_EAST --partitions $PARTITIONS \
  && echo "  OK: $TOPIC_EAST created" \
  || echo "  SKIP: $TOPIC_EAST (see above)"

confluent kafka cluster use $WEST_CLUSTER_ID
confluent api-key use $MANAGER_WEST_KEY --resource $WEST_CLUSTER_ID
confluent kafka topic create $TOPIC_WEST --partitions $PARTITIONS \
  && echo "  OK: $TOPIC_WEST created" \
  || echo "  SKIP: $TOPIC_WEST (see above)"
echo ""

echo ">>> Step 2: Creating cluster links..."
confluent kafka cluster use $WEST_CLUSTER_ID
confluent api-key use $SVC_LINK_WEST_KEY --resource $WEST_CLUSTER_ID
confluent kafka link create vj-aa-east-to-west \
  --source-cluster $EAST_CLUSTER_ID \
  --source-bootstrap-server "$EAST_BOOTSTRAP" \
  --source-api-key $SVC_LINK_EAST_KEY \
  --source-api-secret "$SVC_LINK_EAST_SECRET" \
  && echo "  OK: east-to-west link created" \
  || echo "  SKIP: link (see above)"

confluent kafka cluster use $EAST_CLUSTER_ID
confluent api-key use $SVC_LINK_EAST_KEY --resource $EAST_CLUSTER_ID
confluent kafka link create vj-aa-west-to-east \
  --source-cluster $WEST_CLUSTER_ID \
  --source-bootstrap-server "$WEST_BOOTSTRAP" \
  --source-api-key $SVC_LINK_WEST_KEY \
  --source-api-secret "$SVC_LINK_WEST_SECRET" \
  && echo "  OK: west-to-east link created" \
  || echo "  SKIP: link (see above)"
echo ""

echo ">>> Step 3: Creating mirror topics..."
confluent kafka cluster use $WEST_CLUSTER_ID
confluent api-key use $MANAGER_WEST_KEY --resource $WEST_CLUSTER_ID
confluent kafka mirror create $TOPIC_EAST --link vj-aa-east-to-west \
  && echo "  OK: $TOPIC_EAST mirror on West" \
  || echo "  SKIP: mirror (see above)"

confluent kafka cluster use $EAST_CLUSTER_ID
confluent api-key use $MANAGER_EAST_KEY --resource $EAST_CLUSTER_ID
confluent kafka mirror create $TOPIC_WEST --link vj-aa-west-to-east \
  && echo "  OK: $TOPIC_WEST mirror on East" \
  || echo "  SKIP: mirror (see above)"
echo ""

echo ">>> Step 4: Verifying..."
echo ""
echo "=== East Topics ==="
confluent kafka cluster use $EAST_CLUSTER_ID
confluent api-key use $MANAGER_EAST_KEY --resource $EAST_CLUSTER_ID
confluent kafka topic list
echo ""
echo "=== West Topics ==="
confluent kafka cluster use $WEST_CLUSTER_ID
confluent api-key use $MANAGER_WEST_KEY --resource $WEST_CLUSTER_ID
confluent kafka topic list
echo ""
echo "=== Cluster Links ==="
confluent kafka cluster use $WEST_CLUSTER_ID
confluent api-key use $SVC_LINK_WEST_KEY --resource $WEST_CLUSTER_ID
confluent kafka link list
echo ""
echo "============================================"
echo "  Phase 2 Complete!"
echo "============================================"
echo "  Test: bash scripts/test_replication.sh"
echo ""
