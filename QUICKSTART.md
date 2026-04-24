# Quick Start Guide

Get your IBM Cloud infrastructure up and running in minutes!

## ⚡ 5-Minute Setup

### Step 1: Get Your IBM Cloud API Key

1. Log in to [IBM Cloud](https://cloud.ibm.com)
2. Go to **Manage** → **Access (IAM)** → **API keys**
3. Click **Create an IBM Cloud API key**
4. Copy and save your API key securely

### Step 2: Configure Your Environment

```bash
# Navigate to the project directory
cd ibm-cloud-terraform

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars  # or use your preferred editor
```

**Minimum required configuration:**

```hcl
ibmcloud_api_key = "YOUR_API_KEY_HERE"
region           = "us-south"
resource_group   = "Default"
```

### Step 3: Deploy

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy the infrastructure
terraform apply
```

Type `yes` when prompted to confirm.

## 📋 What Gets Created

- ✅ VPC with 2 subnets (10.240.0.0/24)
- ✅ VPN Gateway for secure access
- ✅ Power VS workspace with 2 Linux instances
- ✅ Transit Gateway connecting VPC and Power VS
- ✅ Security groups and network ACLs

## 🎯 Common Scenarios

### Scenario 1: Minimal Dev Environment

```hcl
vpc_zones               = 1
power_vs_instance_count = 1
power_vs_cores          = 0.5
power_vs_memory         = 8
enable_vpn_gateway      = false
enable_vpe              = false
```

**Cost**: ~$150-250/month

### Scenario 2: Standard Dev/Test (Recommended)

```hcl
vpc_zones               = 2
power_vs_instance_count = 2
power_vs_cores          = 2
power_vs_memory         = 16
enable_vpn_gateway      = true
enable_vpe              = true
```

**Cost**: ~$350-650/month

### Scenario 3: Production-Ready

```hcl
vpc_zones               = 3
power_vs_instance_count = 3
power_vs_cores          = 4
power_vs_memory         = 32
power_vs_processor_type = "dedicated"
power_vs_storage_type   = "tier1"
```

**Cost**: ~$1000-1500/month

## 🔑 Adding SSH Access

Generate an SSH key pair:

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Add the public key to `terraform.tfvars`:

```hcl
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ..."
```

## 🌐 Accessing Your Resources

### After Deployment

```bash
# View all outputs
terraform output

# Get Power VS instance IPs
terraform output power_vs_instance_ips

# Get VPN Gateway IP
terraform output vpn_gateway_public_ip
```

### SSH to Power VS Instances

```bash
# Get the IP address
POWER_IP=$(terraform output -json power_vs_instance_ips | jq -r '.[0]')

# Connect
ssh root@$POWER_IP
```

## 🧪 Verify Connectivity

### From Power VS to VPC

```bash
# SSH to Power VS instance
ssh root@<power-vs-ip>

# Ping VPC subnet
ping 10.240.0.1
```

### From VPC to Power VS

```bash
# From a VPC instance
ping 192.168.10.x
```

## 🛠️ Troubleshooting

### Issue: "Error creating VPC"

**Solution**: Check that your resource group exists

```bash
ibmcloud resource groups
```

### Issue: "Power VS image not found"

**Solution**: List available images for your zone

```bash
ibmcloud pi images --zone us-south
```

Update `power_vs_image_name` in terraform.tfvars

### Issue: "Insufficient quota"

**Solution**: Check your account limits

```bash
ibmcloud is quotas
```

Request quota increase if needed

## 🔄 Making Changes

### Update Configuration

1. Edit `terraform.tfvars`
2. Run `terraform plan` to preview changes
3. Run `terraform apply` to apply changes

### Add More Instances

```hcl
power_vs_instance_count = 3  # Change from 2 to 3
```

```bash
terraform apply
```

## 🗑️ Cleanup

### Remove Everything

```bash
terraform destroy
```

Type `yes` to confirm.

### Remove Specific Resources

```bash
# Remove only VPN Gateway
terraform destroy -target=module.vpn

# Remove only Power VS instances
terraform destroy -target=module.power_vs
```

## 📊 Cost Management

### View Estimated Costs

```bash
# Use IBM Cloud Cost Estimator
ibmcloud billing estimate
```

### Stop Instances When Not in Use

```bash
# Stop Power VS instances
ibmcloud pi instance-stop <instance-id>

# Start when needed
ibmcloud pi instance-start <instance-id>
```

## 🔐 Security Best Practices

1. **Never commit terraform.tfvars** - It's in .gitignore
2. **Rotate API keys regularly** - Every 90 days
3. **Use separate keys per environment** - Dev, test, prod
4. **Enable MFA** - On your IBM Cloud account
5. **Review security groups** - Restrict to known IPs

## 📚 Next Steps

1. ✅ Deploy infrastructure
2. ✅ Verify connectivity
3. ✅ Configure VPN connection (if enabled)
4. ✅ Install applications on Power VS instances
5. ✅ Set up monitoring and logging
6. ✅ Configure backups

## 🆘 Getting Help

- **Documentation**: See [README.md](README.md)
- **IBM Cloud Docs**: https://cloud.ibm.com/docs
- **Terraform Provider**: https://registry.terraform.io/providers/IBM-Cloud/ibm
- **Support**: https://cloud.ibm.com/unifiedsupport/supportcenter

## 💡 Tips

- Start small and scale up
- Use `terraform plan` before every apply
- Keep state files secure
- Document your changes
- Test in dev before prod

---

**Ready to deploy?** Run `terraform init && terraform apply` 🚀