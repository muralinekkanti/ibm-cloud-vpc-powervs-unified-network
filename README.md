# IBM Cloud Terraform Infrastructure

Complete Terraform configuration for deploying IBM Cloud VPC and Power VS infrastructure with secure connectivity.

## 🏗️ Architecture Overview

This Terraform project provisions:

- **VPC** with /24 network (10.240.0.0/24) across multiple availability zones
- **VPN Gateway** with BGP support for secure remote connectivity
- **Virtual Private Endpoint (VPE)** for private Cloud Object Storage access
- **Power VS Workspace** with Linux instances (RHEL/SLES)
- **Transit Gateway** connecting VPC and Power VS networks

### 🆕 BGP Support

The VPN Gateway now supports **BGP (Border Gateway Protocol)** for dynamic routing:
- ✅ Automatic route learning and advertisement
- ✅ Dynamic failover and redundancy
- ✅ Configurable ASNs and routing policies
- ✅ Full IKE/IPsec policy customization
- ✅ Dead Peer Detection (DPD) configuration

See [BGP-CONFIGURATION.md](BGP-CONFIGURATION.md) for detailed setup instructions.

```
┌─────────────────────────────────────────────────────────────┐
│                     IBM Cloud Region                         │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ VPC (10.240.0.0/24)                                    │ │
│  │  ├─ Subnets across 2 zones                            │ │
│  │  ├─ VPN Gateway                                        │ │
│  │  └─ VPE for COS                                        │ │
│  └────────────────────────────────────────────────────────┘ │
│                            │                                 │
│                   ┌────────┴────────┐                       │
│                   │ Transit Gateway │                       │
│                   └────────┬────────┘                       │
│                            │                                 │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Power VS Workspace (192.168.10.0/24)                  │ │
│  │  └─ 2x Linux VMs (RHEL/SLES)                          │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

### Required Tools

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0
- [IBM Cloud CLI](https://cloud.ibm.com/docs/cli?topic=cli-getting-started)
- IBM Cloud account with appropriate permissions

### IBM Cloud Requirements

1. **IBM Cloud Account**: Active account with billing enabled
2. **API Key**: Create at https://cloud.ibm.com/iam/apikeys
3. **Resource Group**: Existing resource group (or use "Default")
4. **COS Instance** (optional): For VPE endpoint

### Required Permissions

Your IBM Cloud API key needs access to:
- VPC Infrastructure Services
- Power Systems Virtual Server
- Transit Gateway
- Cloud Object Storage (for VPE)

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)

Use the automated setup script that checks prerequisites, installs missing tools, and guides you through configuration:

**For Linux/macOS:**
```bash
./quick-setup.sh
```

**For Windows (PowerShell):**
```powershell
.\quick-setup.ps1
```

The script will:
- ✅ Detect your operating system
- ✅ Check and install required tools (Terraform, IBM Cloud CLI, Git/ssh-keygen)
- ✅ Generate SSH keys automatically
- ✅ Prompt for minimal configuration (API key, region, project name)
- ✅ Create terraform.tfvars with your settings
- ✅ Initialize and validate Terraform
- ✅ Optionally deploy infrastructure with one command

**Supported Operating Systems:**
- **Windows**: Windows 10/11 with PowerShell 5.1+ (uses Chocolatey for package management)
- **macOS**: macOS 10.15+ (uses Homebrew for package management)
- **Linux**: Ubuntu/Debian, RHEL/CentOS/Fedora, and other distributions

### Option 2: Manual Setup

#### 1. Clone and Setup

```bash
cd ibm-cloud-terraform
cp terraform.tfvars.example terraform.tfvars
```

#### 2. Configure Variables

Edit `terraform.tfvars` with your values:

```hcl
ibmcloud_api_key = "YOUR_API_KEY"
region           = "us-south"
resource_group   = "Default"
project_name     = "dev-infra"

# Optional: Add SSH key for Power VS access
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E..."

# Optional: Add COS CRN for VPE
cos_instance_crn = "crn:v1:bluemix:public:cloud-object-storage:..."
```

#### 3. Initialize Terraform

```bash
terraform init
```

#### 4. Review Plan

```bash
terraform plan
```

#### 5. Deploy Infrastructure

```bash
terraform apply
```

#### 6. View Outputs

```bash
terraform output
```

## 📁 Project Structure

```
ibm-cloud-terraform/
├── main.tf                    # Main orchestration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── versions.tf                # Provider versions
├── terraform.tfvars.example   # Example configuration
├── README.md                  # This file
├── modules/
│   ├── vpc/                   # VPC module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── vpn/                   # VPN Gateway module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── vpe/                   # VPE module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── power-vs/              # Power VS module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── transit-gateway/       # Transit Gateway module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── examples/
    └── dev-environment/       # Example configurations
```

## ⚙️ Configuration Options

### VPC Configuration

```hcl
vpc_cidr              = "10.240.0.0/24"  # VPC CIDR block
vpc_zones             = 2                 # Number of zones (1-3)
enable_public_gateway = false             # Public internet access
```

### Power VS Configuration

```hcl
power_vs_zone           = "us-south"
power_vs_network_cidr   = "192.168.10.0/24"
power_vs_instance_count = 2
power_vs_image_name     = "RHEL8-SP4"
power_vs_cores          = 2
power_vs_memory         = 16
power_vs_storage_size   = 100
```

### Available Images

**RHEL**: `RHEL8-SP4`, `RHEL8-SP6`, `RHEL9-SP2`  
**SLES**: `SLES15-SP3`, `SLES15-SP4`, `SLES15-SP5`

## 🔐 Security

### Network Security

- **Security Groups**: Control inbound/outbound traffic
- **Network ACLs**: Subnet-level protection
- **VPN Encryption**: IPsec with strong ciphers
- **Private Endpoints**: No public internet exposure for COS

### Access Control

- **SSH Keys**: Required for Power VS instance access
- **IAM Policies**: Least privilege access
- **API Key**: Stored securely (never commit to git)

### Best Practices

1. Store `terraform.tfvars` securely (add to `.gitignore`)
2. Use separate API keys for different environments
3. Enable audit logging with IBM Cloud Activity Tracker
4. Regularly rotate API keys
5. Use dedicated resource groups per environment

## 🧪 Testing and Validation

### Post-Deployment Tests

```bash
# 1. Verify VPC
ibmcloud is vpcs
ibmcloud is subnets

# 2. Check VPN Gateway
ibmcloud is vpn-gateways

# 3. Verify Power VS
ibmcloud pi workspaces
ibmcloud pi instances

# 4. Test connectivity
# SSH to Power VS instance
ssh root@<power-vs-ip>

# Ping VPC subnet from Power VS
ping 10.240.0.x

# Ping Power VS from VPC
ping 192.168.10.x
```

### Terraform Validation

```bash
# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Check for security issues
terraform plan -out=tfplan
```

## 💰 Cost Estimation

### Development Environment (Monthly)

| Component | Estimated Cost |
|-----------|----------------|
| VPC + Subnets | $0 |
| VPN Gateway | $100-150 |
| Power VS (2 instances) | $200-400 |
| Transit Gateway | $50-100 |
| VPE | Minimal (per GB) |
| **Total** | **$350-650** |

### Cost Optimization Tips

1. **Right-size instances**: Start small, scale as needed
2. **Use shared processors**: More cost-effective for dev/test
3. **Tier 3 storage**: Cheaper than Tier 1 for non-critical data
4. **Shut down when not in use**: Stop instances during off-hours
5. **Monitor usage**: Use IBM Cloud Cost Estimator

## 🔧 Troubleshooting

### Common Issues

#### Authentication Errors

```bash
# Verify API key
ibmcloud iam api-keys

# Test authentication
ibmcloud login --apikey YOUR_API_KEY
```

#### VPC Creation Fails

- Check resource group exists
- Verify region is correct
- Ensure sufficient quota

#### Power VS Instance Won't Start

- Verify image name is correct for the zone
- Check available capacity in the zone
- Ensure network CIDR doesn't overlap

#### Transit Gateway Connection Issues

- Verify both VPC and Power VS are in same region
- Check that CRNs are correct
- Wait for connections to fully attach (can take 5-10 minutes)

### Getting Help

```bash
# Check Terraform logs
export TF_LOG=DEBUG
terraform apply

# IBM Cloud support
ibmcloud support case-create

# Provider documentation
https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs
```

## 🔄 Updating Infrastructure

### Modify Configuration

1. Update `terraform.tfvars`
2. Run `terraform plan` to review changes
3. Run `terraform apply` to apply changes

### Add Resources

1. Modify module or add new resources
2. Run `terraform plan`
3. Run `terraform apply`

### Remove Resources

```bash
# Destroy specific resource
terraform destroy -target=module.vpn

# Destroy everything
terraform destroy
```

## 📊 Outputs

After deployment, Terraform provides:

- VPC ID, CRN, and subnet details
- VPN Gateway public IP
- Power VS instance IPs and details
- Transit Gateway connection status
- VPE endpoint information

View outputs:

```bash
terraform output
terraform output -json > outputs.json
```

## 🔗 Additional Resources

- [IBM Cloud Terraform Provider](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)
- [IBM Cloud VPC Documentation](https://cloud.ibm.com/docs/vpc)
- [IBM Power Systems Virtual Server](https://cloud.ibm.com/docs/power-iaas)
- [IBM Transit Gateway](https://cloud.ibm.com/docs/transit-gateway)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

## 📝 License

This project is provided as-is for educational and development purposes.

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📧 Support

For issues or questions:

1. Check the troubleshooting section
2. Review IBM Cloud documentation
3. Open an issue in the repository
4. Contact IBM Cloud support

---

**Note**: This is a development/test configuration. For production use, additional hardening, monitoring, and backup strategies should be implemented.