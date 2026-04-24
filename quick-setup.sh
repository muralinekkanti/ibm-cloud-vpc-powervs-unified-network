#!/bin/bash

# quick-setup.sh - Automated setup script for IBM Cloud VPC-Power VS Unified Network
# This script checks prerequisites, gathers minimal configuration, and prepares the environment

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            OS_VERSION=$VERSION_ID
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        OS_VERSION=$(sw_vers -productVersion)
    else
        OS="unknown"
    fi
    print_info "Detected OS: $OS $OS_VERSION"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Terraform
install_terraform() {
    print_info "Installing Terraform..."
    
    if [[ "$OS" == "macos" ]]; then
        if command_exists brew; then
            brew tap hashicorp/tap
            brew install hashicorp/tap/terraform
        else
            print_error "Homebrew not found. Please install Homebrew first: https://brew.sh"
            exit 1
        fi
    elif [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install -y terraform
    elif [[ "$OS" == "rhel" ]] || [[ "$OS" == "centos" ]] || [[ "$OS" == "fedora" ]]; then
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
        sudo yum -y install terraform
    else
        print_error "Automatic Terraform installation not supported for $OS"
        print_info "Please install Terraform manually: https://www.terraform.io/downloads"
        exit 1
    fi
}

# Install IBM Cloud CLI
install_ibmcloud_cli() {
    print_info "Installing IBM Cloud CLI..."
    
    if [[ "$OS" == "macos" ]]; then
        curl -fsSL https://clis.cloud.ibm.com/install/osx | sh
    elif [[ "$OS" == "linux"* ]] || [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "centos" ]]; then
        curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
    else
        print_error "Automatic IBM Cloud CLI installation not supported for $OS"
        print_info "Please install manually: https://cloud.ibm.com/docs/cli"
        exit 1
    fi
}

# Install jq
install_jq() {
    print_info "Installing jq..."
    
    if [[ "$OS" == "macos" ]]; then
        if command_exists brew; then
            brew install jq
        fi
    elif [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        sudo apt install -y jq
    elif [[ "$OS" == "rhel" ]] || [[ "$OS" == "centos" ]] || [[ "$OS" == "fedora" ]]; then
        sudo yum install -y jq
    fi
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing_tools=()
    
    # Check Terraform
    if command_exists terraform; then
        TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
        print_success "Terraform installed: v$TERRAFORM_VERSION"
    else
        print_warning "Terraform not found"
        missing_tools+=("terraform")
    fi
    
    # Check IBM Cloud CLI
    if command_exists ibmcloud; then
        IBMCLOUD_VERSION=$(ibmcloud version | head -n1 | awk '{print $3}')
        print_success "IBM Cloud CLI installed: v$IBMCLOUD_VERSION"
    else
        print_warning "IBM Cloud CLI not found"
        missing_tools+=("ibmcloud")
    fi
    
    # Check jq
    if command_exists jq; then
        print_success "jq installed"
    else
        print_warning "jq not found (optional but recommended)"
        missing_tools+=("jq")
    fi
    
    # Check ssh-keygen
    if command_exists ssh-keygen; then
        print_success "ssh-keygen available"
    else
        print_error "ssh-keygen not found (required)"
        exit 1
    fi
    
    # Install missing tools
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo ""
        print_warning "Missing tools: ${missing_tools[*]}"
        read -p "Would you like to install missing tools automatically? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for tool in "${missing_tools[@]}"; do
                case $tool in
                    terraform)
                        install_terraform
                        ;;
                    ibmcloud)
                        install_ibmcloud_cli
                        ;;
                    jq)
                        install_jq
                        ;;
                esac
            done
        else
            print_error "Please install missing tools manually and run this script again"
            exit 1
        fi
    fi
}

# Generate SSH key
generate_ssh_key() {
    print_header "SSH Key Setup"
    
    mkdir -p ssh-keys
    
    if [ -f "ssh-keys/example-key.prv" ] && [ -f "ssh-keys/example-key.pub" ]; then
        print_info "SSH key pair already exists in ssh-keys/"
        read -p "Would you like to use the existing key? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            SSH_KEY_PATH="ssh-keys/example-key"
            return
        fi
    fi
    
    print_info "Generating new SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f ssh-keys/example-key -N "" -C "ibm-cloud-terraform"
    mv ssh-keys/example-key ssh-keys/example-key.prv
    chmod 600 ssh-keys/example-key.prv
    chmod 644 ssh-keys/example-key.pub
    
    SSH_KEY_PATH="ssh-keys/example-key"
    print_success "SSH key pair generated: $SSH_KEY_PATH"
}

# Gather configuration
gather_configuration() {
    print_header "Configuration Setup"
    
    # IBM Cloud API Key
    echo ""
    print_info "IBM Cloud API Key is required for authentication"
    print_info "Get your API key from: https://cloud.ibm.com/iam/apikeys"
    read -p "Enter your IBM Cloud API Key: " -s IBMCLOUD_API_KEY
    echo
    
    if [ -z "$IBMCLOUD_API_KEY" ]; then
        print_error "API Key is required"
        exit 1
    fi
    
    # Project Name
    echo ""
    read -p "Enter project name (default: ibm-hybrid-cloud): " PROJECT_NAME
    PROJECT_NAME=${PROJECT_NAME:-ibm-hybrid-cloud}
    
    # Region
    echo ""
    print_info "Available regions: us-south, us-east, eu-gb, eu-de, jp-tok, au-syd"
    read -p "Enter IBM Cloud region (default: us-south): " REGION
    REGION=${REGION:-us-south}
    
    # Zone
    echo ""
    case $REGION in
        us-south)
            print_info "Available zones: us-south-1, us-south-2, us-south-3"
            DEFAULT_ZONE="us-south-1"
            ;;
        us-east)
            print_info "Available zones: us-east-1, us-east-2, us-east-3"
            DEFAULT_ZONE="us-east-1"
            ;;
        eu-gb)
            print_info "Available zones: eu-gb-1, eu-gb-2, eu-gb-3"
            DEFAULT_ZONE="eu-gb-1"
            ;;
        eu-de)
            print_info "Available zones: eu-de-1, eu-de-2, eu-de-3"
            DEFAULT_ZONE="eu-de-1"
            ;;
        *)
            DEFAULT_ZONE="${REGION}-1"
            ;;
    esac
    read -p "Enter zone (default: $DEFAULT_ZONE): " ZONE
    ZONE=${ZONE:-$DEFAULT_ZONE}
    
    # Resource Group
    echo ""
    read -p "Enter resource group (default: Default): " RESOURCE_GROUP
    RESOURCE_GROUP=${RESOURCE_GROUP:-Default}
    
    # Power VS Zone
    echo ""
    print_info "Available Power VS zones: dal10, dal12, us-south, us-east, lon04, lon06, syd04, syd05, tok04, sao01, tor01, mon01, wdc06, wdc07"
    read -p "Enter Power VS zone (default: dal12): " POWER_VS_ZONE
    POWER_VS_ZONE=${POWER_VS_ZONE:-dal12}
}

# Create terraform.tfvars
create_tfvars() {
    print_header "Creating terraform.tfvars"
    
    cat > terraform.tfvars <<EOF
# IBM Cloud Authentication
ibmcloud_api_key = "$IBMCLOUD_API_KEY"

# Project Configuration
project_name    = "$PROJECT_NAME"
region          = "$REGION"
zone            = "$ZONE"
resource_group  = "$RESOURCE_GROUP"

# SSH Key Configuration
vpc_ssh_key_name     = "example-key"
power_vs_ssh_key_name = "example-key"

# Power VS Configuration
power_vs_zone = "$POWER_VS_ZONE"

# Network Configuration (using defaults)
vpc_cidr              = "10.240.0.0/16"
vpc_subnet_cidr       = "10.240.0.0/24"
power_vs_network_cidr = "192.168.100.0/24"

# Transit Gateway Configuration
enable_transit_gateway = true

# NAT Gateway Configuration
enable_nat_gateway = true
EOF
    
    print_success "terraform.tfvars created"
    print_warning "IMPORTANT: Keep terraform.tfvars secure - it contains your API key!"
}

# Display summary
display_summary() {
    print_header "Configuration Summary"
    
    echo "Project Name:      $PROJECT_NAME"
    echo "Region:            $REGION"
    echo "Zone:              $ZONE"
    echo "Resource Group:    $RESOURCE_GROUP"
    echo "Power VS Zone:     $POWER_VS_ZONE"
    echo "SSH Key:           $SSH_KEY_PATH"
    echo ""
    echo "VPC CIDR:          10.240.0.0/16"
    echo "VPC Subnet:        10.240.0.0/24"
    echo "Power VS Network:  192.168.100.0/24"
    echo ""
}

# Initialize Terraform
initialize_terraform() {
    print_header "Initializing Terraform"
    
    print_info "Running terraform init..."
    terraform init
    
    print_success "Terraform initialized"
}

# Validate configuration
validate_terraform() {
    print_header "Validating Configuration"
    
    print_info "Running terraform validate..."
    terraform validate
    
    print_success "Configuration is valid"
}

# Plan deployment
plan_deployment() {
    print_header "Planning Deployment"
    
    print_info "Running terraform plan..."
    terraform plan -out=tfplan
    
    print_success "Plan created: tfplan"
}

# Main execution
main() {
    clear
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   IBM Cloud VPC-Power VS Unified Network                     ║
║   Quick Setup Script                                         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    print_info "This script will help you set up and deploy the infrastructure"
    echo ""
    
    # Detect OS
    detect_os
    
    # Check prerequisites
    check_prerequisites
    
    # Generate SSH key
    generate_ssh_key
    
    # Gather configuration
    gather_configuration
    
    # Create terraform.tfvars
    create_tfvars
    
    # Display summary
    display_summary
    
    # Initialize Terraform
    initialize_terraform
    
    # Validate configuration
    validate_terraform
    
    # Plan deployment
    plan_deployment
    
    # Prompt to apply
    print_header "Ready to Deploy"
    echo ""
    print_warning "This will create real resources in IBM Cloud and incur costs!"
    print_info "Estimated monthly cost: ~\$500-600 USD"
    echo ""
    print_info "Resources to be created:"
    echo "  - 1 VPC with subnet and public gateway"
    echo "  - 1 Ubuntu VSI (NAT Gateway)"
    echo "  - 1 Power VS Workspace"
    echo "  - 3 Power VS LPARs (CentOS, RHEL 9, RHEL 8)"
    echo "  - 1 Transit Gateway"
    echo "  - Network connectivity and routing"
    echo ""
    
    read -p "Do you want to apply this configuration now? (yes/no): " APPLY_CONFIRM
    
    if [ "$APPLY_CONFIRM" = "yes" ]; then
        print_header "Applying Configuration"
        print_info "This may take 20-30 minutes..."
        
        terraform apply tfplan
        
        print_success "Deployment complete!"
        echo ""
        print_info "To view outputs, run: terraform output"
        print_info "To destroy resources, run: terraform destroy"
    else
        print_info "Deployment skipped"
        print_info "To apply later, run: terraform apply tfplan"
        print_info "Or run: terraform apply"
    fi
    
    print_header "Setup Complete"
    print_success "Your environment is ready!"
    echo ""
    print_info "Next steps:"
    echo "  1. Review outputs: terraform output"
    echo "  2. Connect to instances using SSH commands from outputs"
    echo "  3. Test connectivity between VPC and Power VS"
    echo ""
    print_info "Documentation:"
    echo "  - QUICKSTART.md - Detailed setup guide"
    echo "  - README.md - Project overview"
    echo "  - ARCHITECTURE_DIAGRAMS_GUIDE.md - Architecture details"
    echo ""
}

# Run main function
main

# Made with Bob
