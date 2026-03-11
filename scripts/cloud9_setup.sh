#!/bin/bash
set -e

echo "============================================"
echo "  Cloud9 Setup"
echo "============================================"
echo ""

# Disable AWS managed temporary credentials
echo ">>> Disabling AWS managed temporary credentials..."
aws cloud9 update-environment \
  --environment-id $(cat /proc/1/environ 2>/dev/null | tr '\0' '\n' | grep C9_PID | cut -d= -f2 || echo "unknown") \
  --managed-credentials-action DISABLE \
  --region $(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo "us-east-1") \
  2>/dev/null || echo "  (skipped - may need to disable manually via Cloud9 > Preferences > AWS Settings)"

# Also disable via the Cloud9 settings file
SETTINGS_DIR="$HOME/.c9"
if [ -d "$SETTINGS_DIR" ]; then
  echo '{"@aws-managed-credentials":"false"}' > "$SETTINGS_DIR/managed-credentials.settings"
  echo "  Managed credentials disabled via settings file."
fi

# Remove any existing AWS managed credentials
rm -f "$HOME/.aws/credentials" 2>/dev/null || true
echo "  Removed cached credentials."
echo ""

# Verify IAM role (should show your custom role, not Cloud9 managed)
echo ">>> Verifying IAM identity..."
aws sts get-caller-identity || echo "  WARNING: AWS credentials not working. Check IAM instance profile."
echo ""

# Install Terraform
echo ">>> Installing Terraform..."
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
echo "  Terraform version: $(terraform version | head -1)"
echo ""

# Install Confluent CLI
echo ">>> Installing Confluent CLI..."
sudo rpm --import https://packages.confluent.io/confluent-cli/rpm/archive.key
sudo yum install yum-utils
sudo yum-config-manager --add-repo https://packages.confluent.io/confluent-cli/rpm/confluent-cli.repo
sudo yum install confluent-cli
echo "Confluent CLI version: $(confluent version)"
echo ""

# Install jq
echo ">>> Installing jq..."
sudo yum install -y jq
echo ""

echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "  IAM Identity:"
aws sts get-caller-identity --query Arn --output text 2>/dev/null || echo "  (check IAM role)"
echo ""
echo "  Next steps:"
echo "    1. confluent login"
echo "    2. Copy scripts/phase2.env from your Mac"
echo "    3. bash scripts/phase2.sh"
echo ""