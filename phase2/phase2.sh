#!/bin/bash
set -e

# ──────────────────────────────────────────
# Load variables from phase2.env
# Generate this file from phase1 (on your local mac where you run phase1)
#   cd phase1
#   terraform output -raw phase2_env > ../scripts/phase2.env
# copy contents of phase2.env into c9 phase2/phase2.env file
# ──────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/phase2.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found!"
  echo ""
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
echo "  Phase 2 — Topics, Cluster Links, Mirrors"
echo "============================================"
echo ""
echo "Environment:  $ENV_ID"
echo "East Cluster: $EAST_CLUSTER_ID"
echo "West Cluster: $WEST_CLUSTER_ID"
echo ""

# ──────────────────────────────────────────
# Step 1: Create Topics
# ──────────────────────────────────────────

echo ">>> Step 1: Creating topics..."

echo "  Creating $TOPIC_EAST on East cluster..."
confluent kafka topic create $TOPIC_EAST \
  --partitions $PARTITIONS \
  --environment $ENV_ID \
  --cluster $EAST_CLUSTER_ID \
  --api-key $MANAGER_EAST_KEY \
  --api-secret $MANAGER_EAST_SECRET \
  2>/dev/null || echo "  (topic may already exist)"

echo "  Creating $TOPIC_WEST on West cluster..."
confluent kafka topic create $TOPIC_WEST \
  --partitions $PARTITIONS \
  --environment $ENV_ID \
  --cluster $WEST_CLUSTER_ID \
  --api-key $MANAGER_WEST_KEY \
  --api-secret $MANAGER_WEST_SECRET \
  2>/dev/null || echo "  (topic may already exist)"

echo ""

# ──────────────────────────────────────────
# Step 2: Create Cluster Links
# ──────────────────────────────────────────

echo ">>> Step 2: Creating cluster links..."

echo "  Creating vj-aa-east-to-west..."
confluent kafka link create vj-aa-east-to-west \
  --source-cluster $EAST_CLUSTER_ID \
  --source-bootstrap-server $EAST_BOOTSTRAP \
  --source-api-key $SVC_LINK_EAST_KEY \
  --source-api-secret $SVC_LINK_EAST_SECRET \
  --environment $ENV_ID \
  --cluster $WEST_CLUSTER_ID \
  --api-key $SVC_LINK_WEST_KEY \
  --api-secret $SVC_LINK_WEST_SECRET \
  2>/dev/null || echo "  (link may already exist)"

echo "  Creating vj-aa-west-to-east..."
confluent kafka link create vj-aa-west-to-east \
  --source-cluster $WEST_CLUSTER_ID \
  --source-bootstrap-server $WEST_BOOTSTRAP \
  --source-api-key $SVC_LINK_WEST_KEY \
  --source-api-secret $SVC_LINK_WEST_SECRET \
  --environment $ENV_ID \
  --cluster $EAST_CLUSTER_ID \
  --api-key $SVC_LINK_EAST_KEY \
  --api-secret $SVC_LINK_EAST_SECRET \
  2>/dev/null || echo "  (link may already exist)"

echo ""

# ──────────────────────────────────────────
# Step 3: Create Mirror Topics
# ──────────────────────────────────────────

echo ">>> Step 3: Creating mirror topics..."

echo "  Mirroring $TOPIC_EAST to West..."
confluent kafka mirror create $TOPIC_EAST \
  --link vj-aa-east-to-west \
  --environment $ENV_ID \
  --cluster $WEST_CLUSTER_ID \
  --api-key $MANAGER_WEST_KEY \
  --api-secret $MANAGER_WEST_SECRET \
  2>/dev/null || echo "  (mirror may already exist)"

echo "  Mirroring $TOPIC_WEST to East..."
confluent kafka mirror create $TOPIC_WEST \
  --link vj-aa-west-to-east \
  --environment $ENV_ID \
  --cluster $EAST_CLUSTER_ID \
  --api-key $MANAGER_EAST_KEY \
  --api-secret $MANAGER_EAST_SECRET \
  2>/dev/null || echo "  (mirror may already exist)"

echo ""

# ──────────────────────────────────────────
# Step 4: Verify
# ──────────────────────────────────────────

echo ">>> Step 4: Verifying..."
echo ""

echo "=== East Cluster Topics ==="
confluent kafka topic list \
  --environment $ENV_ID \
  --cluster $EAST_CLUSTER_ID \
  --api-key $MANAGER_EAST_KEY \
  --api-secret $MANAGER_EAST_SECRET

echo ""
echo "=== West Cluster Topics ==="
confluent kafka topic list \
  --environment $ENV_ID \
  --cluster $WEST_CLUSTER_ID \
  --api-key $MANAGER_WEST_KEY \
  --api-secret $MANAGER_WEST_SECRET

echo ""
echo "=== Cluster Links ==="
confluent kafka link list \
  --environment $ENV_ID \
  --cluster $WEST_CLUSTER_ID \
  --api-key $SVC_LINK_WEST_KEY \
  --api-secret $SVC_LINK_WEST_SECRET

echo ""
echo "============================================"
echo "  Phase 2 Complete!"
echo "============================================"
echo ""
echo "  Test: bash scripts/test_replication.sh"
echo ""