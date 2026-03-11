# Multi-Region Active-Active Kafka on Confluent Cloud

End-to-end Terraform project that deploys a bidirectional, multi-region Kafka
architecture on Confluent Cloud with AWS PrivateLink, including all underlying
AWS networking and a Cloud9 workstation.

## Architecture
Confluent Cloud
+--------------------------------------------------+
|                 Environment                      |


|              (vj-aa-linkedpl)                     |
|                                                  |
|  +----------------+       +----------------+     |
|  |  East Cluster   |<-CL-->|  West Cluster   |   |
|  |  (DEDICATED)    |       |  (DEDICATED)    |   |


|  |  us-east-1      |       |  us-west-2      |   |
|  |                 |       |                 |   |
|  |  orders_east ---mirror--> orders_east     |   |
|  |  orders_west <-mirror--- orders_west     |   |
|  +--------+--------+       +--------+--------+   |
|           | Network Link            | Network Link|
+-----------+-------------------------+-------------+
|                         |
+-----------+-------------------------+-------------+
|           |       AWS Account       |             |
|  +--------+--------+       +--------+--------+   |
|  |  East VPC       |       |  West VPC       |   |
|  |  10.0.0.0/16    |<-PCX-->|  10.1.0.0/16    |   |
|  |  +-----------+  |       | +-----------+  |   |
|  |  |PrivateLink|  |       | |PrivateLink|  |   |
|  |  |VPC Endpt  |  |       | |VPC Endpt  |  |   |
|  |  +-----------+  |       | +-----------+  |   |
|  |  +-----------+  |       +----------------+   |
|  |  |  Cloud9   |  |                             |
|  |  |  (SSM)    |  |                             |
|  |  +-----------+  |                             |
|  +----------------+                             |
+--------------------------------------------------+

## Two-Phase Deployment

This project is split into two phases because PrivateLink clusters have
REST endpoints that resolve to private IPs only reachable from inside
the VPCs.

- Phase 1: Run from your Mac (public API calls)
- Phase 2: Run from Cloud9 (private API calls via PrivateLink)

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI v2 configured with credentials
- Confluent Cloud account with a Cloud API Key
- IAM Role (e.g. EC2TerraformAdminRole) for Cloud9 instance profile

## AWS Authentication

Before running Terraform, configure AWS credentials:

Option A - AWS SSO (recommended for Confluent employees):

    aws sso login --profile your-profile-name
    export AWS_PROFILE=your-profile-name

Option B - IAM Access Keys:

    aws configure

Option C - Environment Variables:

    export AWS_ACCESS_KEY_ID="AKIAXXXXXXXXXX"
    export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxxxxxxxxx"
    export AWS_DEFAULT_REGION="us-east-1"

Verify:

    aws sts get-caller-identity

## Phase 1 - Infrastructure (from Mac, ~35 min)

Phase 1 creates everything that can be done via public APIs:
VPCs, peering, Cloud9, Confluent clusters, PrivateLink, RBAC, API keys.

    cd phase1
    cp terraform.tfvars.example terraform.tfvars
    # Edit terraform.tfvars with your values
    terraform init
    terraform apply

Phase 1 creates these resources in order:

    Min 0-2     VPCs, subnets, IGWs, NATs, route tables (east + west)
    Min 2-3     VPC peering, cross-region routes, DNS resolution
    Min 3-5     SSM endpoints, Cloud9, IAM swap, disk resize
    Min 3-5     Confluent environment, networks, PrivateLink access
    Min 5-30    DEDICATED Kafka cluster provisioning (parallel)
    Min 30-31   AWS PrivateLink VPC endpoints + Route53 zones
    Min 31-32   Route53 zone associations + west SG rules
    Min 32-33   Confluent network link services + endpoints
    Min 33-34   Service accounts + RBAC bindings + 60s propagation sleep
    Min 34-35   API keys (disable_wait_for_ready for PrivateLink)

After apply, generate the Phase 2 environment file:

    terraform output -raw phase2_env > ../scripts/phase2.env

## Phase 2 - Topics, Links, Mirrors (from Cloud9, ~2 min)

Phase 2 creates resources that require PrivateLink access:
topics, cluster links, mirror topics.

Step 1 - Open Cloud9:

    terraform output cloud9_url
    # Open the URL in your browser

Step 2 - In Cloud9 terminal, clone the repo:

    git clone git@github.com:vj-beep/CFLT-Terraform.git
    cd CFLT-Terraform

Step 3 - Install tools (first time only):

    bash scripts/cloud9_setup.sh

Step 4 - Copy phase2.env from your Mac to Cloud9:

    # The file was generated in Phase 1:
    #   terraform output -raw phase2_env > ../scripts/phase2.env
    # Copy scripts/phase2.env to the Cloud9 scripts/ directory

Step 5 - Run Phase 2:

    bash scripts/phase2.sh

Step 6 - Test replication:

    bash scripts/test_replication.sh

## terraform.tfvars Reference

    # AWS
    vpc_name_east    = "east"
    vpc_name_west    = "west"
    vpc_tag          = "confluent-demo"

    # Cloud9
    cloud9_name      = "workstation"
    cloud9_owner_arn = "arn:aws:sts::123456789012:assumed-role/YourRole/user"
    cloud9_iam_role  = "EC2TerraformAdminRole"
    cloud9_disk_size = 500

    # Confluent Cloud
    confluent_cloud_api_key    = ""
    confluent_cloud_api_secret = ""
    aws_account_id             = "123456789012"

    cluster_type         = "DEDICATED"
    cluster_name_east    = "core-app-east"
    cluster_name_west    = "core-app-west"
    environment_name     = "vj-aa-linkedpl"
    cluster_availability = "SINGLE_ZONE"
    cluster_cku          = 1

    topic_name_east       = "orders_east"
    topic_name_west       = "orders_west"
    consumer_group_prefix = "orders-consumer"

    # Set to false to skip disabling Cloud9 managed credentials
    cloud9_disable_managed_creds = false

## File Structure

    phase1/
      providers.tf               AWS + Confluent + time providers
      variables.tf               All inputs with validation
      locals.tf                  VPC CIDRs, AZs, cluster type conditionals
      main.tf                    VPC module calls (east + west)
      peering.tf                 VPC peering, routes, west PL SG rules
      cloud9.tf                  Cloud9 + SSM endpoints + post-creation
      dns.tf                     Cross-region Route53 zone associations
      environment.tf             Confluent environment, networks, PL access
      clusters.tf                Kafka clusters + AWS PrivateLink modules
      network-links.tf           Bidirectional Confluent network links
      rbac.tf                    Service accounts, RBAC, time_sleep
      api-keys.tf                Scoped API keys (disable_wait_for_ready)
      outputs.tf                 VPC IDs, cluster IDs, API keys, phase2_env
      terraform.tfvars.example   Template (safe to commit)
      scripts/
        swap_profile.sh          IAM instance profile swap
        resize_disk.sh           EBS volume resize + filesystem grow
      modules/
        vpc/                     Reusable VPC module
        aws-privatelink/         Reusable PrivateLink module

    scripts/
      cloud9_setup.sh            Install Terraform + Confluent CLI + jq
      phase2.sh                  Create topics, cluster links, mirror topics
      test_replication.sh        Produce to East, consume mirror from West
      teardown.sh                Delete Phase 2 resources
      phase2.env                 Generated - contains all IDs and secrets

## What Phase 1 Creates

    AWS VPCs (32 resources)
      2 VPCs, 12 subnets, 2 IGWs, 2 NATs, 4 route tables

    VPC Peering (10 resources)
      Peering connection, accepter, DNS options, 4 routes, 2 SG rules

    Cloud9 (13 resources)
      Environment, 3 SSM endpoints, 2 SGs, IAM profile, null_resources

    Confluent Environment (5 resources)
      Environment, 2 networks, 2 PrivateLink access grants

    Kafka Clusters (2 resources)
      2 DEDICATED clusters (1 CKU each)

    AWS PrivateLink (14 resources)
      2 SGs, 2 VPC endpoints, 2 Route53 zones, 6 DNS records

    Cross-Region DNS (2 resources)
      2 Route53 zone associations

    Network Links (4 resources)
      2 services, 2 endpoints

    RBAC (14 resources)
      4 service accounts, 8 role bindings, 1 time_sleep

    API Keys (10 resources)
      10 scoped API keys

    Phase 1 Total: ~107 resources

## What Phase 2 Creates (via CLI)

    2 Kafka topics (orders_east, orders_west)
    2 Cluster links (east-to-west, west-to-east)
    2 Mirror topics (bidirectional)

    Phase 2 Total: 6 resources

## Cluster Types

    BASIC       Public networking, no cluster linking, ACLs only
    STANDARD    Public networking, limited cluster linking, granular RBAC
    DEDICATED   PrivateLink, full cluster linking, granular RBAC
    ENTERPRISE  PrivateLink, full cluster linking, auto-scaling

## Key Design Decisions

    Cloud9 inside east VPC
      No extra peering needed to reach PrivateLink endpoints

    Auto Route53 zone association
      West zone linked to east VPC via module output

    disable_wait_for_ready on API keys
      Provider cannot reach private REST endpoint to validate

    time_sleep (60s) after RBAC
      Prevents 401 from role binding propagation delay

    CRN format: {crn}/kafka={id}/topic={name}
      Three-part path required by Confluent API

    Plan-time AZ ID lookup
      data.aws_availability_zone resolves at plan time
      Avoids for_each unknown key errors

    External bash scripts for null_resource
      Avoids heredoc escaping conflicts between Terraform and bash

    Phase 2 as CLI scripts (not Terraform)
      Topics, cluster links, mirror topics need PrivateLink access
      Simpler than managing separate Terraform state

## Troubleshooting

    No valid credential sources found
      Run: aws configure or aws sso login

    dial tcp 10.x.x.x:443 i/o timeout
      Route53 zone or SG rule not ready. Re-run terraform apply

    401 Unauthorized on topic creation
      RBAC propagation delay. Re-run terraform apply

    no matching EC2 Instance found
      Cloud9 instance not running yet. Re-run terraform apply
      (time_sleep handles this on fresh deploys)

    for_each keys unknown after apply
      Fixed with data.aws_availability_zone lookup at plan time

## Secrets Management

Never commit terraform.tfvars, phase2.env, or .tfstate files to Git.

For CI/CD:

    export TF_VAR_confluent_cloud_api_key="$VAULT_KEY"
    export TF_VAR_confluent_cloud_api_secret="$VAULT_SECRET"

## Execution Summary

    PHASE 1 - Mac (~35 min)
      cd phase1
      cp terraform.tfvars.example terraform.tfvars
      # edit terraform.tfvars
      terraform init
      terraform apply
      terraform output -raw phase2_env > ../scripts/phase2.env

    PHASE 2 - Cloud9 (~2 min)
      # Open Cloud9 (URL from: terraform output cloud9_url)
      git clone git@github.com:vj-beep/CFLT-Terraform.git
      cd CFLT-Terraform
      bash scripts/cloud9_setup.sh
      # Copy scripts/phase2.env from Mac
      bash scripts/phase2.sh
      bash scripts/test_replication.sh

    TEARDOWN
      Cloud9:  bash scripts/teardown.sh
      Mac:     cd phase1 && terraform destroy
