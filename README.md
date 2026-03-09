# Multi-Region Active-Active Kafka on Confluent Cloud

End-to-end Terraform project that deploys a **bidirectional, multi-region Kafka
architecture** on Confluent Cloud with AWS PrivateLink — including all underlying
AWS networking and a Cloud9 workstation.

## Architecture
Confluent Cloud
┌──────────────────────────────────────────────────┐
│                 Environment                      │
│              (vj-aa-linkedpl)                     │
│                                                  │
│  ┌────────────────┐       ┌────────────────┐     │
│  │  East Cluster   │◄─CL──►│  West Cluster   │   │
│  │  (DEDICATED)    │       │  (DEDICATED)    │   │
│  │  us-east-1      │       │  us-west-2      │   │
│  │                 │       │                 │   │
│  │  orders_east ───mirror──► orders_east     │   │
│  │  orders_west ◄─mirror─── orders_west     │   │
│  └───────┬─────────┘       └───────┬─────────┘   │
│          │ Network Link            │ Network Link│
└──────────┼─────────────────────────┼─────────────┘
│                         │
┌──────────┼─────────────────────────┼─────────────┐
│          │       AWS Account       │             │
│  ┌───────┴────────┐       ┌───────┴────────┐    │
│  │  East VPC       │       │  West VPC       │    │
│  │  10.0.0.0/16    │◄─PCX──►│  10.1.0.0/16    │    │
│  │  ┌────────────┐ │       │ ┌────────────┐ │    │
│  │  │ PrivateLink│ │       │ │ PrivateLink│ │    │
│  │  │ VPC Endpt  │ │       │ │ VPC Endpt  │ │    │
│  │  └────────────┘ │       │ └────────────┘ │    │
│  │  ┌────────────┐ │       └────────────────┘    │
│  │  │  Cloud9    │ │                      │
│  │  │  (SSM)     │ │                             │
│  │  └────────────┘ │                             │
│  └────────────────┘                             │
└──────────────────────────────────────────────────┘

## Prerequisites

- **Terraform** >= 1.5.0
- **AWS CLI v2** configured with credentials
- **Confluent Cloud** account with a Cloud API Key
- **IAM Role** (e.g. `EC2TerraformAdminRole`) for Cloud9 instance profile

## AWS Authentication

Before running Terraform, configure AWS credentials using one of these methods:

### Option A: AWS SSO (recommended for Confluent employees)

bash
aws sso login --profile your-profile-name
export AWS_PROFILE=your-profile-name

### Option B: IAM Access Keys

bash
aws configure
Enter: AWS Access Key ID, Secret Access Key, region (us-east-1)

### Option C: Environment Variables

bash
export AWS_ACCESS_KEY_ID="AKIAXXXXXXXXXX"
export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxxxxxxxxx"
export AWS_DEFAULT_REGION="us-east-1"

### Verify credentials work

bash
aws sts get-caller-identity

You should see your Account ID and ARN.

## Quick Start

bash
1. Clone
git clone git@github.com:vj-beep/CFLT-Terraform.git
cd CFLT-Terraform

2. Create your variables file
cp terraform.tfvars.example terraform.tfvars

Edit terraform.tfvars with your actual values
3. Initialize
terraform init

4. Deploy (~35 min)
terraform apply

5. If any timeouts on first run, just re-run (idempotent)
terraform apply

6. Check outputs
terraform output


## terraform.tfvars Reference

hcl
AWS
vpc_name_east    = "east"
vpc_name_west    = "west"
vpc_tag          = "confluent-demo"

Cloud9 — get owner ARN with: aws sts get-caller-identity --query Arn --output text
cloud9_name      = "workstation"
cloud9_owner_arn = "arn:aws:sts::123456789012:assumed-role/YourRole/user@example.com"
cloud9_iam_role  = "EC2TerraformAdminRole"
cloud9_disk_size = 500

Confluent Cloud — create at:  https://confluent.cloud/settings/api-keys
confluent_cloud_api_key    = "ABCDEF1234567890"
confluent_cloud_api_secret = "your-secret-here"
aws_account_id             = "123456789012"   # aws sts get-caller-identity --query Account --output text

cluster_type         = "DEDICATED"
cluster_name_east    = "core-app-east"
cluster_name_west    = "core-app-west"
environment_name     = "vj-aa-linkedpl"
cluster_availability = "SINGLE_ZONE"
cluster_cku          = 1

topic_name_east       = "orders_east"
topic_name_west       = "orders_west"
consumer_group_prefix = "orders-consumer"


## Execution Timeline (~35 min)

Everything deploys in a **single `terraform apply`**:

Minute 0-2      VPCs, subnets, IGWs, NATs, route tables
Minute 2-3      VPC peering, cross-region routes
Minute 3-5      SSM endpoints, Cloud9 environment, IAM swap, disk resize
Minute 3-5      Confluent environment, networks, PrivateLink access grants
Minute 5-30     DEDICATED Kafka cluster provisioning (both regions, parallel)
Minute 30-32    AWS PrivateLink VPC endpoints + Route53 zones
Minute 32-33    Route53 zone associations + west SG rules for east CIDR
Minute 33-34    Confluent network link services + endpoints
Minute 34-35    Service accounts + RBAC role bindings + 60s propagation sleep
Minute 35-36    API keys (disable_wait_for_ready for PrivateLink)
Minute 36-37    Topics (orders_east, orders_west)
Minute 37-38    Cluster links (east-to-west, west-to-east)
Minute 38-39    Mirror topics (bidirectional replication)


## Testing with Cloud9

Cloud9 is needed for testing produce/consume because the Kafka clusters are behind PrivateLink and only reachable from inside the VPCs. **You do NOT need Cloud9 to run Terraform.**

### Step 1: Open Cloud9

bash
terraform output cloud9_url

Copy the URL and open it in your browser.

### Step 2: Install Confluent CLI (inside Cloud9 terminal)

bash
curl -sL --http1.1  https://cnfl.io/cli | sh -s -- latest
export PATH="$HOME/bin:$PATH"
echo 'export PATH="$HOME/bin:$PATH"' 
~/.bashrc
confluent version

### Step 3: Log in to Confluent Cloud

bash
confluent login

### Step 4: Produce to East cluster

bash
Get values from: terraform output (on your original machine)
confluent kafka topic produce orders_east 
  --environment env-XXXXX 
  --cluster lkc-XXXXX 
  --api-key XXXXXXXXXX 
  --api-secret XXXXXXXXXX


Type test messages:

json
{"number":1,"date":18500,"shipping_address":"899 W Evelyn Ave, Mountain View, CA","cost":15.00}
{"number":2,"date":18501,"shipping_address":"1 Bedford St, London WC2E 9HG, UK","cost":5.00}


Press `Ctrl+C` when done.

### Step 5: Consume mirror from West cluster (proves replication)

bash
Use WEST cluster ID and WEST API keys
confluent kafka topic consume orders_east 
  --from-beginning 
  --environment env-XXXXX 
  --cluster lkc-YYYYY 
  --api-key YYYYYYYYYY 
  --api-secret YYYYYYYYYY


The topic name `orders_east` on the west cluster is the **mirror topic** — you should see the same messages you produced to east.

### Quick Test Script

Save this as `test.sh` in Cloud9 and fill in your values:

bash
#!/bin/bash
ENV_ID="env-XXXXX"
EAST_ID="lkc-XXXXX"
WEST_ID="lkc-YYYYY"
EAST_KEY="AAAAAAAAAA"
EAST_SECRET="xxxxxxxxxx"
WEST_KEY="BBBBBBBBBB"
WEST_SECRET="yyyyyyyyyy"

echo "=== Producing 3 records to East ==="
echo '{"order":1,"item":"widget","cost":10.00}
{"order":2,"item":"gadget","cost":25.00}
{"order":3,"item":"doohickey","cost":5.00}' | 
confluent kafka topic produce orders_east 
  --environment $ENV_ID --cluster $EAST_ID 
  --api-key $EAST_KEY --api-secret $EAST_SECRET

echo ""
echo "=== Waiting 5s for replication ==="
sleep 5

echo ""
echo "=== Consuming mirror from West (Ctrl+C to stop) ==="
confluent kafka topic consume orders_east 
  --from-beginning 
  --environment $ENV_ID --cluster $WEST_ID 
  --api-key $WEST_KEY --api-secret $WEST_SECRET


bash
chmod +x test.sh
./test.sh


## File Structure

├── providers.tf               # AWS (east/west) + Confluent + time providers
├── variables.tf               # All inputs with validation
├── locals.tf                  # VPC CIDRs, AZs, cluster type conditionals
├── main.tf                    # VPC module calls (east + west)
├── peering.tf                 # VPC peering, routes, west PL SG rules
├── cloud9.tf                  # Cloud9 + SSM endpoints + post-creation steps
├── dns.tf                     # Cross-region Route53 zone associations (auto)
├── environment.tf             # Confluent environment, networks, PL access
├── clusters.tf                # Kafka clusters + AWS PrivateLink modules
├── network-links.tf           # Bidirectional Confluent network links
├── rbac.tf                    # Service accounts, RBAC, ACL fallback, time_sleep
├── api-keys.tf                # Scoped API keys (disable_wait_for_ready)
├── topics.tf                  # Kafka topics (orders_east, orders_west)
├── cluster-links.tf           # Cluster links + mirror topics
├── outputs.tf                 # VPC IDs, cluster IDs, endpoints, API keys
├── terraform.tfvars.example   # Template (safe to commit)
├── .gitignore                 # Excludes state, secrets, .terraform/
├── modules/
│   ├── vpc/
│   │   ├── main.tf            # VPC, subnets, IGW, NAT, route tables
│   │   └── outputs.tf         # VPC ID, subnet IDs, subnets_to_privatelink
│   └── aws-privatelink/
│       ├── main.tf            # SG, VPC endpoint, Route53 zone, DNS records
│       └── variables.tf


## Cluster Types

| Type | Networking | Cluster Linking | RBAC | Cost |
|------|-----------|----------------|------|------|
| `BASIC` | Public | No | ACLs only | $ |
| `STANDARD` | Public | Limited | Granular RBAC | 
[ |
| `DEDICATED` | PrivateLink | Full bidirectional | Granular RBAC | ]
$ |
| `ENTERPRISE` | PrivateLink | Full bidirectional | Granular RBAC | 
[]
 |

## Key Design Decisions

| Decision | Why |
|----------|-----|
| Cloud9 inside east VPC | No extra peering needed to reach PrivateLink |
| Auto Route53 zone association | West zone linked to east VPC via module output — no manual step |
| `disable_wait_for_ready` on API keys | Provider cannot reach private REST endpoint to validate |
| `time_sleep` (60s) after RBAC | Prevents 401 from role binding propagation delay |
| CRN `{crn}/kafka={id}/topic={name}` | Three-part path required by Confluent API |
| Plan-time AZ ID lookup | `data.aws_availability_zone` resolves AZ IDs at plan, avoiding `for_each` unknown key errors |
| ACL fallback for BASIC | BASIC clusters do not support granular RBAC roles |

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `No valid credential sources found` | AWS CLI not configured | Run `aws configure` or `aws sso login` then `export AWS_PROFILE=...` |
| `dial tcp 10.x.x.x:443: i/o timeout` | Route53 zone association or SG rule not ready | Re-run `terraform apply` |
| `401 Unauthorized` on topic creation | RBAC propagation delay | Re-run `terraform apply` (time_sleep handles it on fresh deploys) |
| `No role DeveloperWrite for KafkaTopic` | Wrong CRN format | Already fixed — uses `/kafka={id}/topic={name}` |
| `for_each keys unknown after apply` | Subnet AZ IDs computed at apply time | Already fixed — uses data source AZ lookup at plan time |
| Cloud9 `AccessDeniedException` | Managed creds disabled after IAM swap | Already fixed — disable runs before swap |

## Secrets Management

**Never commit `terraform.tfvars` or `.tfstate` files to Git.**

For CI/CD pipelines:

bash
export TF_VAR_confluent_cloud_api_key="$VAULT_KEY"
export TF_VAR_confluent_cloud_api_secret="$VAULT_SECRET"

For production, use HashiCorp Vault or AWS Secrets Manager.

## Teardown

bash
terraform destroy

## Where to Run What

| Task | Where | When |
|------|-------|------|
| `terraform init` + `apply` | Your laptop or any workstation with AWS CLI | Once (~35 min) |
| Re-run `terraform apply` if timeouts | Same workstation | Immediately after |
| Open Cloud9 IDE | Browser (URL from `terraform output`) | After apply completes |
| Install Confluent CLI | Inside Cloud9 terminal | Once |
| Produce/consume testing | Inside Cloud9 terminal | Anytime |
| `terraform destroy` | Your original workstation | When done |