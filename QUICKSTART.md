# Quick Start Guide

Get your IBM Cloud VPC-Power VS unified network infrastructure up and running in minutes!

## ⚡ Prerequisites

Before you begin, ensure you have:

- ✅ IBM Cloud account with appropriate permissions
- ✅ Terraform installed (v1.0+)
- ✅ IBM Cloud CLI installed (optional, for key management)
- ✅ SSH key pair generated

## 📦 Step 1: Clone the Repository

```bash
git clone https://github.com/muralinekkanti/ibm-cloud-vpc-powervs-unified-network.git
cd ibm-cloud-vpc-powervs-unified-network
```

## 🔑 Step 2: Get Your IBM Cloud API Key

1. Log in to [IBM Cloud](https://cloud.ibm.com)
2. Go to **Manage** → **Access (IAM)** → **[API keys](https://cloud.ibm.com/iam/apikeys)**
3. Click **Create an IBM Cloud API key**
4. Give it a name (e.g., "Terraform Deployment")
5. **Copy and save your API key securely** (you won't see it again!)

## 🔐 Step 3: Set Up SSH Keys

### Generate SSH Keys (if you don't have them)

```bash
# Generate a new SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ibm-cloud-key -N ""

# This creates:
# - Private key: ~/.ssh/ibm-cloud-key
# - Public key: ~/.ssh/ibm-cloud-key.pub
```

### Add SSH Key to IBM Cloud VPC

```bash
# Using IBM Cloud CLI
ibmcloud login --apikey YOUR_API_KEY
ibmcloud target -r us-east
ibmcloud is key-create my-vpc-key @~/.ssh/ibm-cloud-key.pub

# Or via Web Console:
# https://cloud.ibm.com/vpc-ext/compute/sshKeys
```

### Copy SSH Keys to Project Directory

```bash
# Copy your private key to the project directory
cp ~/.ssh/ibm-cloud-key ./ssh-keys/ibm-cloud-key.prv
cp ~/.ssh/ibm-cloud-key.pub ./ssh-keys/ibm-cloud-key.pub

# Set correct permissions
chmod 600 ./ssh-keys/ibm-cloud-key.prv
```

**Note**: The project uses `ssh-keys/` directory for SSH keys, which is excluded from Git via `.gitignore`.

## ⚙️ Step 4: Configure Your Environment

```bash
# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars  # or use your preferred editor
```

### Required Configuration

Edit `terraform.tfvars` and set these **required** values:

```hcl
# IBM Cloud API Key (from Step 2)
ibmcloud_api_key = "YOUR_IBM_CLOUD_API_KEY_HERE"

# Project name (used as prefix for all resources)
project_name = "my-vpc-pvs"

# Region and zone
region = "us-east"
zone   = "us-east-1"

# Resource group ID
# Find yours: ibmcloud resource groups
resource_group_id = "YOUR_RESOURCE_GROUP_ID"

# SSH key names
vpc_ssh_key_name       = "my-vpc-key"  # Name from Step 3
secondary_ssh_key_name = "my-vpc-key"  # Can be same as above
power_vs_ssh_key_name  = "my-power-key"

# Power VS zone (must be in same region as VPC)
power_vs_zone = "wdc06"  # For us-east region
```

### Find Your Resource Group ID

```bash
# List all resource groups
ibmcloud resource groups

# Get specific group ID
ibmcloud resource group Default --id
```

## 🚀 Step 5: Deploy Infrastructure

```bash
# Initialize Terraform (downloads providers)
terraform init

# Review what will be created (optional but recommended)
terraform plan

# Deploy the infrastructure
terraform apply
```

Type `yes` when prompted to confirm.

**Deployment time**: 15-20 minutes (Power VS LPARs take longest)

## 📋 What Gets Created

### VPC Infrastructure (x86)
- ✅ VPC with subnet (10.14.105.0/24)
- ✅ 3 Ubuntu VSIs (2 vCPUs, 4GB RAM each)
- ✅ 1 Windows VSI (2 vCPUs, 4GB RAM)
- ✅ NAT Gateway VSI (10.14.105.254)
- ✅ Security groups and routing tables
- ✅ Public gateway and 3 floating IPs

### Power Virtual Server Infrastructure (Power)
- ✅ Power VS workspace in wdc06
- ✅ Private network (192.168.1.0/24)
- ✅ 3 LPARs:
  - CentOS Stream 10 (0.25 cores, 2GB RAM)
  - RHEL 9 (0.25 cores, 2GB RAM)
  - RHEL 8 (0.25 cores, 2GB RAM)
- ✅ Secondary IPs for unified addressing
- ✅ Power VS routes for LPAR-to-LPAR communication

### Connectivity
- ✅ Transit Gateway connecting VPC and Power VS
- ✅ NAT Gateway for address translation
- ✅ VPC custom routes for unified subnet

**Total Resources**: ~41 resources  
**Estimated Cost**: ~$200-300/month (varies by region and usage)

## 🎯 Verify Deployment

After deployment completes, Terraform will output connection information:

```bash
# View all outputs
terraform output

# Test connectivity from Ubuntu VSI
ssh -i ~/.ssh/ibm-cloud-key ubuntu@<FLOATING_IP>

# From Ubuntu VSI, ping Power VS LPARs using unified addresses
ping 10.14.105.5  # CentOS LPAR
ping 10.14.105.7  # RHEL 9 LPAR
ping 10.14.105.9  # RHEL 8 LPAR

# SSH to Power VS LPARs via unified addresses
ssh -i ~/.ssh/ibm-cloud-key root@10.14.105.5
```

## 🔧 Common Scenarios

### Scenario 1: Development/Testing (Current Configuration)

**What you get**:
- 3 Ubuntu VSIs + 1 Windows VSI in VPC
- 3 Power VS LPARs (minimal sizing)
- Full connectivity via unified network

**Cost**: ~$200-300/month

### Scenario 2: Production-Ready

Edit `terraform.tfvars`:

```hcl
# Increase VSI sizing
vsi_profile = "cx2-4x8"  # 4 vCPUs, 8GB RAM

# Increase Power VS LPAR sizing
power_vs_processors = 1.0
power_vs_memory = 8
power_vs_storage_type = "tier1"  # Faster storage
```

**Cost**: ~$500-700/month

## 🛠️ Management Commands

```bash
# View current infrastructure state
terraform show

# Update infrastructure (after changing terraform.tfvars)
terraform apply

# Destroy all infrastructure
terraform destroy

# View specific output
terraform output vsi_floating_ip
terraform output nat_gateway_floating_ip
```

## 📚 Additional Resources

- **Architecture Details**: See `README.md`
- **SSH Key Setup**: See `SSH_KEY_SETUP_GUIDE.md`
- **Configuration Reference**: See `TERRAFORM_CONFIGURATION_SUMMARY.md`
- **Git Setup**: See `GIT_SETUP_GUIDE.md` (if contributing)

## ❓ Troubleshooting

### Issue: "Resource group not found"

```bash
# List available resource groups
ibmcloud resource groups

# Use the correct ID in terraform.tfvars
```

### Issue: "SSH key not found"

```bash
# List VPC SSH keys
ibmcloud is keys

# Create if missing
ibmcloud is key-create my-vpc-key @~/.ssh/ibm-cloud-key.pub
```

### Issue: "Power VS zone not available"

Available zones by region:
- **us-east**: wdc06, wdc07
- **us-south**: dal12, dal13
- **eu-gb**: lon04, lon06
- **eu-de**: fra04, fra05
- **jp-tok**: tok04
- **au-syd**: syd04, syd05

### Issue: "Insufficient permissions"

Ensure your IBM Cloud account has:
- VPC Infrastructure Services permissions
- Power Systems Virtual Server permissions
- Transit Gateway permissions

## 🎉 Success!

Once deployed, you have a fully functional hybrid cloud infrastructure with:
- ✅ VPC (x86) and Power VS (Power) on a unified network
- ✅ Seamless communication between x86 and Power workloads
- ✅ NAT gateway for address translation
- ✅ Transit Gateway for automatic routing
- ✅ Production-ready security groups and networking

**Next Steps**:
1. Deploy your applications to the VSIs and LPARs
2. Test connectivity between systems
3. Configure monitoring and logging
4. Set up backup and disaster recovery

## 💰 Cost Management

To minimize costs during testing:

```bash
# Stop (but don't destroy) when not in use
# Note: You'll still pay for storage and some services

# Destroy everything when done testing
terraform destroy
```

**Remember**: Always run `terraform destroy` when you're done to avoid ongoing charges!

## 🆘 Need Help?

- Review the detailed documentation in `README.md`
- Check `TERRAFORM_CONFIGURATION_SUMMARY.md` for configuration options
- See `SSH_KEY_SETUP_GUIDE.md` for SSH troubleshooting
- Open an issue on GitHub for bugs or questions