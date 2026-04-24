# SSH Key Setup Guide

## Overview

A new secondary SSH key has been created and stored in the project directory for secure access to all infrastructure components.

## Key Location

- **Private Key**: `ssh-keys/secondary-key-rsa`
- **Public Key**: `ssh-keys/secondary-key-rsa.pub`
- **Key Type**: RSA 4096-bit
- **Fingerprint**: `SHA256:YvsvY3zgEH3XsYgN9163f67jI6evBCsqG2Ica1Xhe5Y`

## Security

✅ **Protected**: The `ssh-keys/` directory is excluded from git via `.gitignore`  
✅ **Secure**: Private keys will never be committed to version control  
✅ **Backup**: Keys are stored locally in the project directory

---

## Manual Setup Instructions

Since automated deployment encountered connection issues, follow these manual steps to add the secondary SSH key to all servers.

### Step 1: Get the Public Key

```bash
cat ssh-keys/secondary-key-rsa.pub
```

Copy the entire output (starts with `ssh-rsa AAAAB3...`)

### Step 2: Add Key to VPC Servers

#### NAT Gateway (150.239.85.62)

```bash
# SSH to NAT Gateway using existing key
ssh -i ~/.ssh/murali-key-n1-rsa.prv root@150.239.85.62

# Add the secondary key
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDsDZOQMc1t2qdu/WvsiExdzpFV0ZSxxUZI6o3p56MAVOBN0eYDI/bSVaxZc9hKJ96K63KIPBYOVkStubDiqIK3AeSlHKLCvhy/zQ8SCLIO5hFJC2Eb4xil1DEkeClB+Wegcc/REOHw0UNOTuTtMf2iz8bd0bkQ1FZNm99Rvaixf0txfEK+DZjm7cPzCAlOg3XYGCI0Zh1rCWG6KAL0/t6LrKnsKtyfFu3cfDrvv/jz+QCqYDtlvySU+ujWTbpYCtUax1t8ODNHNyCmcEfN4tvFHE/zc5sck1FA1EW9WwrcTXR2QL3UWBkcMFpKFIGJs6j6xM4WNf3B2nstGgqU/Zdz/TMz25ChgktaX2qN8Vp2AD1kq2IkR01EeBDleU5Pu59VGOez9JZ8KiO/tVgkvFlMxed+b/2vsfoyrYGW79TaXyVRS4TwONXwxZjNSscvRQ+5YjLfWwli5pHq9DuFifC6wesBnluK2Paj28maS0OiMIUGGC8xOwHkyaUtjc0dcD5N03lqRqlXzQFGnexG1cZpY9zWCXNLyclAqKeuBcz3txgybaZnDCzH22wWt6pHKBvBghupfsWZQujcqIRtyqfyoCLNY2jnLtnXiKkR2EFLtBkgXuT10FYdUo/R+MeEKDd+EHNOdX6bYWeJMjg0N4fh9tPs/lIwP7q1cfgQsz/OQ== secondary-access-key' >> ~/.ssh/authorized_keys

# Remove duplicates
sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys

# Verify
cat ~/.ssh/authorized_keys
```

#### Windows VSI (52.116.123.166)

1. RDP to the Windows server
2. Open PowerShell as Administrator
3. Run:

```powershell
# Create SSH directory if it doesn't exist
New-Item -ItemType Directory -Force -Path "$env:ProgramData\ssh"

# Add the key
Add-Content -Path "$env:ProgramData\ssh\administrators_authorized_keys" -Value 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDsDZOQMc1t2qdu/WvsiExdzpFV0ZSxxUZI6o3p56MAVOBN0eYDI/bSVaxZc9hKJ96K63KIPBYOVkStubDiqIK3AeSlHKLCvhy/zQ8SCLIO5hFJC2Eb4xil1DEkeClB+Wegcc/REOHw0UNOTuTtMf2iz8bd0bkQ1FZNm99Rvaixf0txfEK+DZjm7cPzCAlOg3XYGCI0Zh1rCWG6KAL0/t6LrKnsKtyfFu3cfDrvv/jz+QCqYDtlvySU+ujWTbpYCtUax1t8ODNHNyCmcEfN4tvFHE/zc5sck1FA1EW9WwrcTXR2QL3UWBkcMFpKFIGJs6j6xM4WNf3B2nstGgqU/Zdz/TMz25ChgktaX2qN8Vp2AD1kq2IkR01EeBDleU5Pu59VGOez9JZ8KiO/tVgkvFlMxed+b/2vsfoyrYGW79TaXyVRS4TwONXwxZjNSscvRQ+5YjLfWwli5pHq9DuFifC6wesBnluK2Paj28maS0OiMIUGGC8xOwHkyaUtjc0dcD5N03lqRqlXzQFGnexG1cZpY9zWCXNLyclAqKeuBcz3txgybaZnDCzH22wWt6pHKBvBghupfsWZQujcqIRtyqfyoCLNY2jnLtnXiKkR2EFLtBkgXuT10FYdUo/R+MeEKDd+EHNOdX6bYWeJMjg0N4fh9tPs/lIwP7q1cfgQsz/OQ== secondary-access-key'

# Set correct permissions
icacls "$env:ProgramData\ssh\administrators_authorized_keys" /inheritance:r
icacls "$env:ProgramData\ssh\administrators_authorized_keys" /grant "SYSTEM:(F)"
icacls "$env:ProgramData\ssh\administrators_authorized_keys" /grant "BUILTIN\Administrators:(F)"
```

### Step 3: Add Key to Power VS Servers

#### CentOS LPAR (10.14.105.5)

```bash
# SSH via NAT Gateway
ssh -i ~/.ssh/murali-key-n1-rsa.prv -J root@150.239.85.62 root@10.14.105.5

# Add the secondary key
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDsDZOQMc1t2qdu/WvsiExdzpFV0ZSxxUZI6o3p56MAVOBN0eYDI/bSVaxZc9hKJ96K63KIPBYOVkStubDiqIK3AeSlHKLCvhy/zQ8SCLIO5hFJC2Eb4xil1DEkeClB+Wegcc/REOHw0UNOTuTtMf2iz8bd0bkQ1FZNm99Rvaixf0txfEK+DZjm7cPzCAlOg3XYGCI0Zh1rCWG6KAL0/t6LrKnsKtyfFu3cfDrvv/jz+QCqYDtlvySU+ujWTbpYCtUax1t8ODNHNyCmcEfN4tvFHE/zc5sck1FA1EW9WwrcTXR2QL3UWBkcMFpKFIGJs6j6xM4WNf3B2nstGgqU/Zdz/TMz25ChgktaX2qN8Vp2AD1kq2IkR01EeBDleU5Pu59VGOez9JZ8KiO/tVgkvFlMxed+b/2vsfoyrYGW79TaXyVRS4TwONXwxZjNSscvRQ+5YjLfWwli5pHq9DuFifC6wesBnluK2Paj28maS0OiMIUGGC8xOwHkyaUtjc0dcD5N03lqRqlXzQFGnexG1cZpY9zWCXNLyclAqKeuBcz3txgybaZnDCzH22wWt6pHKBvBghupfsWZQujcqIRtyqfyoCLNY2jnLtnXiKkR2EFLtBkgXuT10FYdUo/R+MeEKDd+EHNOdX6bYWeJMjg0N4fh9tPs/lIwP7q1cfgQsz/OQ== secondary-access-key' >> ~/.ssh/authorized_keys

# Remove duplicates
sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys
```

#### RHEL 9 LPAR (10.14.105.7)

```bash
# SSH via NAT Gateway
ssh -i ~/.ssh/murali-key-n1-rsa.prv -J root@150.239.85.62 root@10.14.105.7

# Add the secondary key
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDsDZOQMc1t2qdu/WvsiExdzpFV0ZSxxUZI6o3p56MAVOBN0eYDI/bSVaxZc9hKJ96K63KIPBYOVkStubDiqIK3AeSlHKLCvhy/zQ8SCLIO5hFJC2Eb4xil1DEkeClB+Wegcc/REOHw0UNOTuTtMf2iz8bd0bkQ1FZNm99Rvaixf0txfEK+DZjm7cPzCAlOg3XYGCI0Zh1rCWG6KAL0/t6LrKnsKtyfFu3cfDrvv/jz+QCqYDtlvySU+ujWTbpYCtUax1t8ODNHNyCmcEfN4tvFHE/zc5sck1FA1EW9WwrcTXR2QL3UWBkcMFpKFIGJs6j6xM4WNf3B2nstGgqU/Zdz/TMz25ChgktaX2qN8Vp2AD1kq2IkR01EeBDleU5Pu59VGOez9JZ8KiO/tVgkvFlMxed+b/2vsfoyrYGW79TaXyVRS4TwONXwxZjNSscvRQ+5YjLfWwli5pHq9DuFifC6wesBnluK2Paj28maS0OiMIUGGC8xOwHkyaUtjc0dcD5N03lqRqlXzQFGnexG1cZpY9zWCXNLyclAqKeuBcz3txgybaZnDCzH22wWt6pHKBvBghupfsWZQujcqIRtyqfyoCLNY2jnLtnXiKkR2EFLtBkgXuT10FYdUo/R+MeEKDd+EHNOdX6bYWeJMjg0N4fh9tPs/lIwP7q1cfgQsz/OQ== secondary-access-key' >> ~/.ssh/authorized_keys

# Remove duplicates
sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys
```

#### RHEL 8 LPAR (10.14.105.9)

```bash
# SSH via NAT Gateway
ssh -i ~/.ssh/murali-key-n1-rsa.prv -J root@150.239.85.62 root@10.14.105.9

# Add the secondary key
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDsDZOQMc1t2qdu/WvsiExdzpFV0ZSxxUZI6o3p56MAVOBN0eYDI/bSVaxZc9hKJ96K63KIPBYOVkStubDiqIK3AeSlHKLCvhy/zQ8SCLIO5hFJC2Eb4xil1DEkeClB+Wegcc/REOHw0UNOTuTtMf2iz8bd0bkQ1FZNm99Rvaixf0txfEK+DZjm7cPzCAlOg3XYGCI0Zh1rCWG6KAL0/t6LrKnsKtyfFu3cfDrvv/jz+QCqYDtlvySU+ujWTbpYCtUax1t8ODNHNyCmcEfN4tvFHE/zc5sck1FA1EW9WwrcTXR2QL3UWBkcMFpKFIGJs6j6xM4WNf3B2nstGgqU/Zdz/TMz25ChgktaX2qN8Vp2AD1kq2IkR01EeBDleU5Pu59VGOez9JZ8KiO/tVgkvFlMxed+b/2vsfoyrYGW79TaXyVRS4TwONXwxZjNSscvRQ+5YjLfWwli5pHq9DuFifC6wesBnluK2Paj28maS0OiMIUGGC8xOwHkyaUtjc0dcD5N03lqRqlXzQFGnexG1cZpY9zWCXNLyclAqKeuBcz3txgybaZnDCzH22wWt6pHKBvBghupfsWZQujcqIRtyqfyoCLNY2jnLtnXiKkR2EFLtBkgXuT10FYdUo/R+MeEKDd+EHNOdX6bYWeJMjg0N4fh9tPs/lIwP7q1cfgQsz/OQ== secondary-access-key' >> ~/.ssh/authorized_keys

# Remove duplicates
sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys
```

---

## Verification

### Test VPC Connections

```bash
# Test NAT Gateway
ssh -i ssh-keys/secondary-key-rsa root@150.239.85.62 "echo 'NAT Gateway: OK'"

# Test Windows (after manual setup)
ssh -i ssh-keys/secondary-key-rsa Administrator@52.116.123.166 "echo 'Windows VSI: OK'"
```

### Test Power VS Connections

```bash
# Test CentOS LPAR
ssh -i ssh-keys/secondary-key-rsa -J root@150.239.85.62 root@10.14.105.5 "echo 'CentOS LPAR: OK'"

# Test RHEL 9 LPAR
ssh -i ssh-keys/secondary-key-rsa -J root@150.239.85.62 root@10.14.105.7 "echo 'RHEL 9 LPAR: OK'"

# Test RHEL 8 LPAR
ssh -i ssh-keys/secondary-key-rsa -J root@150.239.85.62 root@10.14.105.9 "echo 'RHEL 8 LPAR: OK'"
```

---

## Usage Examples

### Direct Connection to VPC

```bash
# NAT Gateway
ssh -i ssh-keys/secondary-key-rsa root@150.239.85.62

# Windows VSI
ssh -i ssh-keys/secondary-key-rsa Administrator@52.116.123.166
```

### Connection to Power VS via Jump Host

```bash
# CentOS LPAR
ssh -i ssh-keys/secondary-key-rsa -J root@150.239.85.62 root@10.14.105.5

# RHEL 9 LPAR
ssh -i ssh-keys/secondary-key-rsa -J root@150.239.85.62 root@10.14.105.7

# RHEL 8 LPAR
ssh -i ssh-keys/secondary-key-rsa -J root@150.239.85.62 root@10.14.105.9
```

### SCP File Transfer

```bash
# To NAT Gateway
scp -i ssh-keys/secondary-key-rsa file.txt root@150.239.85.62:/tmp/

# To Power VS LPAR via jump host
scp -i ssh-keys/secondary-key-rsa -J root@150.239.85.62 file.txt root@10.14.105.5:/tmp/
```

---

## Server Inventory

| Server | IP Address | Username | Access Method |
|--------|------------|----------|---------------|
| NAT Gateway | 150.239.85.62 | root | Direct |
| Windows VSI | 52.116.123.166 | Administrator | Direct |
| CentOS LPAR | 10.14.105.5 | root | Via NAT Gateway |
| RHEL 9 LPAR | 10.14.105.7 | root | Via NAT Gateway |
| RHEL 8 LPAR | 10.14.105.9 | root | Via NAT Gateway |

---

## Troubleshooting

### Permission Denied

If you get "Permission denied (publickey)":

1. Verify the key was added correctly:
   ```bash
   ssh -i ~/.ssh/murali-key-n1-rsa.prv root@SERVER_IP "cat ~/.ssh/authorized_keys"
   ```

2. Check file permissions:
   ```bash
   ssh -i ~/.ssh/murali-key-n1-rsa.prv root@SERVER_IP "ls -la ~/.ssh/"
   ```

3. Ensure correct permissions:
   ```bash
   ssh -i ~/.ssh/murali-key-n1-rsa.prv root@SERVER_IP "chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
   ```

### Connection Timeout

If connection times out:

1. Verify floating IPs are correct
2. Check security group rules allow SSH (port 22)
3. Verify NAT gateway is running for Power VS access

### Key Not Working

1. Verify key file permissions locally:
   ```bash
   chmod 600 ssh-keys/secondary-key-rsa
   chmod 644 ssh-keys/secondary-key-rsa.pub
   ```

2. Test with verbose output:
   ```bash
   ssh -vvv -i ssh-keys/secondary-key-rsa root@150.239.85.62
   ```

---

## Security Best Practices

1. ✅ **Never commit private keys** - Already protected by `.gitignore`
2. ✅ **Use strong passphrases** - Consider adding passphrase to private key
3. ✅ **Limit key access** - Keep file permissions at 600 for private keys
4. ✅ **Regular rotation** - Rotate keys periodically
5. ✅ **Audit access** - Monitor SSH logs for unauthorized access attempts

---

## Automated Script

An automated script is available: `add-secondary-ssh-key.sh`

However, due to current connection issues, manual setup is recommended.

---

**Document Version**: 1.0  
**Last Updated**: April 13, 2026  
**Status**: Manual setup required