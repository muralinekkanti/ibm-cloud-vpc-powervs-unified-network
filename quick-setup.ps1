# quick-setup.ps1 - Automated setup script for IBM Cloud VPC-Power VS Unified Network (Windows)
# This script checks prerequisites, gathers minimal configuration, and prepares the environment

#Requires -Version 5.1

# Set error action preference
$ErrorActionPreference = "Stop"

# Color functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if command exists
function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Install Chocolatey
function Install-Chocolatey {
    Write-Info "Installing Chocolatey package manager..."
    
    if (-not (Test-Administrator)) {
        Write-Error "Administrator privileges required to install Chocolatey"
        Write-Info "Please run this script as Administrator"
        exit 1
    }
    
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Install Terraform
function Install-Terraform {
    Write-Info "Installing Terraform..."
    
    if (Test-CommandExists choco) {
        choco install terraform -y
    } else {
        Write-Info "Downloading Terraform manually..."
        $terraformVersion = "1.7.0"
        $downloadUrl = "https://releases.hashicorp.com/terraform/${terraformVersion}/terraform_${terraformVersion}_windows_amd64.zip"
        $downloadPath = "$env:TEMP\terraform.zip"
        $installPath = "$env:ProgramFiles\Terraform"
        
        Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath
        Expand-Archive -Path $downloadPath -DestinationPath $installPath -Force
        
        # Add to PATH
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        if ($currentPath -notlike "*$installPath*") {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$installPath", "Machine")
        }
        
        Remove-Item $downloadPath
    }
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Install IBM Cloud CLI
function Install-IBMCloudCLI {
    Write-Info "Installing IBM Cloud CLI..."
    
    $downloadUrl = "https://download.clis.cloud.ibm.com/ibm-cloud-cli/2.23.0/IBM_Cloud_CLI_2.23.0_windows_amd64.exe"
    $downloadPath = "$env:TEMP\ibmcloud-cli-installer.exe"
    
    Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath
    Start-Process -FilePath $downloadPath -ArgumentList "/VERYSILENT" -Wait
    Remove-Item $downloadPath
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Install Git (includes ssh-keygen)
function Install-Git {
    Write-Info "Installing Git..."
    
    if (Test-CommandExists choco) {
        choco install git -y
    } else {
        Write-Info "Downloading Git manually..."
        $downloadUrl = "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe"
        $downloadPath = "$env:TEMP\git-installer.exe"
        
        Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath
        Start-Process -FilePath $downloadPath -ArgumentList "/VERYSILENT" -Wait
        Remove-Item $downloadPath
    }
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Check prerequisites
function Test-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    $missingTools = @()
    
    # Check Terraform
    if (Test-CommandExists terraform) {
        $terraformVersion = (terraform version -json | ConvertFrom-Json).terraform_version
        Write-Success "Terraform installed: v$terraformVersion"
    } else {
        Write-Warning "Terraform not found"
        $missingTools += "terraform"
    }
    
    # Check IBM Cloud CLI
    if (Test-CommandExists ibmcloud) {
        $ibmcloudVersion = (ibmcloud version | Select-String -Pattern "ibmcloud version" | ForEach-Object { $_.Line -replace ".*version ", "" })
        Write-Success "IBM Cloud CLI installed: v$ibmcloudVersion"
    } else {
        Write-Warning "IBM Cloud CLI not found"
        $missingTools += "ibmcloud"
    }
    
    # Check ssh-keygen (comes with Git)
    if (Test-CommandExists ssh-keygen) {
        Write-Success "ssh-keygen available"
    } else {
        Write-Warning "ssh-keygen not found (Git required)"
        $missingTools += "git"
    }
    
    # Install missing tools
    if ($missingTools.Count -gt 0) {
        Write-Host ""
        Write-Warning "Missing tools: $($missingTools -join ', ')"
        $response = Read-Host "Would you like to install missing tools automatically? (y/n)"
        
        if ($response -eq 'y' -or $response -eq 'Y') {
            # Check for Chocolatey
            if (-not (Test-CommandExists choco)) {
                Write-Info "Chocolatey not found. Installing..."
                Install-Chocolatey
            }
            
            foreach ($tool in $missingTools) {
                switch ($tool) {
                    "terraform" { Install-Terraform }
                    "ibmcloud" { Install-IBMCloudCLI }
                    "git" { Install-Git }
                }
            }
            
            Write-Success "All tools installed successfully"
        } else {
            Write-Error "Please install missing tools manually and run this script again"
            exit 1
        }
    }
}

# Generate SSH key
function New-SSHKey {
    Write-Header "SSH Key Setup"
    
    $sshKeysDir = "ssh-keys"
    if (-not (Test-Path $sshKeysDir)) {
        New-Item -ItemType Directory -Path $sshKeysDir | Out-Null
    }
    
    $privateKeyPath = "$sshKeysDir\example-key.prv"
    $publicKeyPath = "$sshKeysDir\example-key.pub"
    
    if ((Test-Path $privateKeyPath) -and (Test-Path $publicKeyPath)) {
        Write-Info "SSH key pair already exists in $sshKeysDir\"
        $response = Read-Host "Would you like to use the existing key? (y/n)"
        
        if ($response -eq 'y' -or $response -eq 'Y') {
            return "$sshKeysDir\example-key"
        }
    }
    
    Write-Info "Generating new SSH key pair..."
    $keyPath = "$sshKeysDir\example-key"
    
    # Generate key without .prv extension first
    ssh-keygen -t rsa -b 4096 -f $keyPath -N '""' -C "ibm-cloud-terraform"
    
    # Rename to .prv extension
    if (Test-Path $keyPath) {
        Move-Item -Path $keyPath -Destination $privateKeyPath -Force
    }
    
    Write-Success "SSH key pair generated: $keyPath"
    return $keyPath
}

# Gather configuration
function Get-Configuration {
    Write-Header "Configuration Setup"
    
    # IBM Cloud API Key
    Write-Host ""
    Write-Info "IBM Cloud API Key is required for authentication"
    Write-Info "Get your API key from: https://cloud.ibm.com/iam/apikeys"
    $apiKey = Read-Host "Enter your IBM Cloud API Key" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey)
    $script:IBMCLOUD_API_KEY = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    if ([string]::IsNullOrWhiteSpace($script:IBMCLOUD_API_KEY)) {
        Write-Error "API Key is required"
        exit 1
    }
    
    # Project Name
    Write-Host ""
    $projectName = Read-Host "Enter project name (default: ibm-hybrid-cloud)"
    $script:PROJECT_NAME = if ([string]::IsNullOrWhiteSpace($projectName)) { "ibm-hybrid-cloud" } else { $projectName }
    
    # Region
    Write-Host ""
    Write-Info "Available regions: us-south, us-east, eu-gb, eu-de, jp-tok, au-syd"
    $region = Read-Host "Enter IBM Cloud region (default: us-south)"
    $script:REGION = if ([string]::IsNullOrWhiteSpace($region)) { "us-south" } else { $region }
    
    # Zone
    Write-Host ""
    $defaultZone = switch ($script:REGION) {
        "us-south" { "us-south-1"; Write-Info "Available zones: us-south-1, us-south-2, us-south-3" }
        "us-east" { "us-east-1"; Write-Info "Available zones: us-east-1, us-east-2, us-east-3" }
        "eu-gb" { "eu-gb-1"; Write-Info "Available zones: eu-gb-1, eu-gb-2, eu-gb-3" }
        "eu-de" { "eu-de-1"; Write-Info "Available zones: eu-de-1, eu-de-2, eu-de-3" }
        default { "$($script:REGION)-1" }
    }
    $zone = Read-Host "Enter zone (default: $defaultZone)"
    $script:ZONE = if ([string]::IsNullOrWhiteSpace($zone)) { $defaultZone } else { $zone }
    
    # Resource Group
    Write-Host ""
    $resourceGroup = Read-Host "Enter resource group (default: Default)"
    $script:RESOURCE_GROUP = if ([string]::IsNullOrWhiteSpace($resourceGroup)) { "Default" } else { $resourceGroup }
    
    # Power VS Zone
    Write-Host ""
    Write-Info "Available Power VS zones: dal10, dal12, us-south, us-east, lon04, lon06, syd04, syd05, tok04, sao01, tor01, mon01, wdc06, wdc07"
    $powerVsZone = Read-Host "Enter Power VS zone (default: dal12)"
    $script:POWER_VS_ZONE = if ([string]::IsNullOrWhiteSpace($powerVsZone)) { "dal12" } else { $powerVsZone }
}

# Create terraform.tfvars
function New-TerraformVars {
    Write-Header "Creating terraform.tfvars"
    
    $tfvarsContent = @"
# IBM Cloud Authentication
ibmcloud_api_key = "$($script:IBMCLOUD_API_KEY)"

# Project Configuration
project_name    = "$($script:PROJECT_NAME)"
region          = "$($script:REGION)"
zone            = "$($script:ZONE)"
resource_group  = "$($script:RESOURCE_GROUP)"

# SSH Key Configuration
vpc_ssh_key_name     = "example-key"
power_vs_ssh_key_name = "example-key"

# Power VS Configuration
power_vs_zone = "$($script:POWER_VS_ZONE)"

# Network Configuration (using defaults)
vpc_cidr              = "10.240.0.0/16"
vpc_subnet_cidr       = "10.240.0.0/24"
power_vs_network_cidr = "192.168.100.0/24"

# Transit Gateway Configuration
enable_transit_gateway = true

# NAT Gateway Configuration
enable_nat_gateway = true
"@
    
    Set-Content -Path "terraform.tfvars" -Value $tfvarsContent
    
    Write-Success "terraform.tfvars created"
    Write-Warning "IMPORTANT: Keep terraform.tfvars secure - it contains your API key!"
}

# Display summary
function Show-Summary {
    Write-Header "Configuration Summary"
    
    Write-Host "Project Name:      $($script:PROJECT_NAME)"
    Write-Host "Region:            $($script:REGION)"
    Write-Host "Zone:              $($script:ZONE)"
    Write-Host "Resource Group:    $($script:RESOURCE_GROUP)"
    Write-Host "Power VS Zone:     $($script:POWER_VS_ZONE)"
    Write-Host "SSH Key:           ssh-keys\example-key"
    Write-Host ""
    Write-Host "VPC CIDR:          10.240.0.0/16"
    Write-Host "VPC Subnet:        10.240.0.0/24"
    Write-Host "Power VS Network:  192.168.100.0/24"
    Write-Host ""
}

# Initialize Terraform
function Initialize-Terraform {
    Write-Header "Initializing Terraform"
    
    Write-Info "Running terraform init..."
    terraform init
    
    Write-Success "Terraform initialized"
}

# Validate configuration
function Test-TerraformConfig {
    Write-Header "Validating Configuration"
    
    Write-Info "Running terraform validate..."
    terraform validate
    
    Write-Success "Configuration is valid"
}

# Plan deployment
function New-TerraformPlan {
    Write-Header "Planning Deployment"
    
    Write-Info "Running terraform plan..."
    terraform plan -out=tfplan
    
    Write-Success "Plan created: tfplan"
}

# Main execution
function Main {
    Clear-Host
    
    Write-Host @"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   IBM Cloud VPC-Power VS Unified Network                     ║
║   Quick Setup Script (Windows)                               ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Green
    
    Write-Info "This script will help you set up and deploy the infrastructure"
    Write-Host ""
    
    # Check if running as Administrator for installations
    if (-not (Test-Administrator)) {
        Write-Warning "Not running as Administrator"
        Write-Info "Some installations may require Administrator privileges"
        Write-Info "If tool installation fails, please run as Administrator"
        Write-Host ""
    }
    
    # Detect Windows version
    $osVersion = [System.Environment]::OSVersion.Version
    Write-Info "Detected OS: Windows $($osVersion.Major).$($osVersion.Minor)"
    
    # Check prerequisites
    Test-Prerequisites
    
    # Generate SSH key
    New-SSHKey
    
    # Gather configuration
    Get-Configuration
    
    # Create terraform.tfvars
    New-TerraformVars
    
    # Display summary
    Show-Summary
    
    # Initialize Terraform
    Initialize-Terraform
    
    # Validate configuration
    Test-TerraformConfig
    
    # Plan deployment
    New-TerraformPlan
    
    # Prompt to apply
    Write-Header "Ready to Deploy"
    Write-Host ""
    Write-Warning "This will create real resources in IBM Cloud and incur costs!"
    Write-Info "Estimated monthly cost: ~`$500-600 USD"
    Write-Host ""
    Write-Info "Resources to be created:"
    Write-Host "  - 1 VPC with subnet and public gateway"
    Write-Host "  - 1 Ubuntu VSI (NAT Gateway)"
    Write-Host "  - 1 Power VS Workspace"
    Write-Host "  - 3 Power VS LPARs (CentOS, RHEL 9, RHEL 8)"
    Write-Host "  - 1 Transit Gateway"
    Write-Host "  - Network connectivity and routing"
    Write-Host ""
    
    $applyConfirm = Read-Host "Do you want to apply this configuration now? (yes/no)"
    
    if ($applyConfirm -eq "yes") {
        Write-Header "Applying Configuration"
        Write-Info "This may take 20-30 minutes..."
        
        terraform apply tfplan
        
        Write-Success "Deployment complete!"
        Write-Host ""
        Write-Info "To view outputs, run: terraform output"
        Write-Info "To destroy resources, run: terraform destroy"
    } else {
        Write-Info "Deployment skipped"
        Write-Info "To apply later, run: terraform apply tfplan"
        Write-Info "Or run: terraform apply"
    }
    
    Write-Header "Setup Complete"
    Write-Success "Your environment is ready!"
    Write-Host ""
    Write-Info "Next steps:"
    Write-Host "  1. Review outputs: terraform output"
    Write-Host "  2. Connect to instances using SSH commands from outputs"
    Write-Host "  3. Test connectivity between VPC and Power VS"
    Write-Host ""
    Write-Info "Documentation:"
    Write-Host "  - QUICKSTART.md - Detailed setup guide"
    Write-Host "  - README.md - Project overview"
    Write-Host "  - ARCHITECTURE_DIAGRAMS_GUIDE.md - Architecture details"
    Write-Host ""
}

# Run main function
try {
    Main
} catch {
    Write-Error "An error occurred: $_"
    Write-Host $_.ScriptStackTrace
    exit 1
}

# Made with Bob
