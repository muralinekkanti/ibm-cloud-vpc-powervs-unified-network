#!/bin/bash
# Script to configure secondary IPs on PowerVS LPARs
# Run this from the VPC VSI (150.239.86.202)

echo "Configuring secondary IPs on PowerVS LPARs..."
echo "=============================================="

# Configure CentOS LPAR (192.168.1.5 -> 10.14.105.5)
echo ""
echo "1. Configuring CentOS LPAR (192.168.1.5)..."
ssh -i ~/.ssh/murali-key-n1-rsa.prv -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@192.168.1.5 'ip addr add 10.14.105.5/24 dev env2 2>/dev/null; CONNECTION=$(nmcli -t -f NAME connection show | grep env2 | head -1); if [ -n "$CONNECTION" ]; then nmcli connection modify "$CONNECTION" +ipv4.addresses 10.14.105.5/24; nmcli connection up "$CONNECTION"; fi; echo "CentOS LPAR IPs:"; ip addr show env2 | grep "inet "'

# Configure RHEL 9 LPAR (192.168.1.7 -> 10.14.105.7)
echo ""
echo "2. Configuring RHEL 9 LPAR (192.168.1.7)..."
ssh -i ~/.ssh/murali-key-n1-rsa.prv -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@192.168.1.7 'ip addr add 10.14.105.7/24 dev env2 2>/dev/null; CONNECTION=$(nmcli -t -f NAME connection show | grep env2 | head -1); if [ -n "$CONNECTION" ]; then nmcli connection modify "$CONNECTION" +ipv4.addresses 10.14.105.7/24; nmcli connection up "$CONNECTION"; fi; echo "RHEL 9 LPAR IPs:"; ip addr show env2 | grep "inet "'

# Configure RHEL 8 LPAR (192.168.1.9 -> 10.14.105.9)
echo ""
echo "3. Configuring RHEL 8 LPAR (192.168.1.9)..."
ssh -i ~/.ssh/murali-key-n1-rsa.prv -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@192.168.1.9 'ip addr add 10.14.105.9/24 dev env2 2>/dev/null; CONNECTION=$(nmcli -t -f NAME connection show | grep env2 | head -1); if [ -n "$CONNECTION" ]; then nmcli connection modify "$CONNECTION" +ipv4.addresses 10.14.105.9/24; nmcli connection up "$CONNECTION"; fi; echo "RHEL 8 LPAR IPs:"; ip addr show env2 | grep "inet "'

echo ""
echo "=============================================="
echo "Configuration complete!"
echo ""
echo "Test connectivity:"
echo "  ping -I 10.14.105.5 10.14.105.7"
echo "  ping -I 10.14.105.5 10.14.105.9"

# Made with Bob
