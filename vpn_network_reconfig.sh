#!/bin/bash

# Script to configure VPN network settings: Remove default gateway and set DNS

dns_servers="1.1.1.1 1.0.0.1"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Try running with sudo."
    exit 1
fi

# Function to remove default gateway for a given interface
remove_default_gateway() {
    local interface=$1
    echo "Removing default gateway for interface: $interface"
    route delete default -ifscope $interface

    if [ $? -eq 0 ]; then
        echo "Default gateway removed for interface $interface."
    else
        echo "Failed to remove default gateway for interface $interface."
    fi
}

# Function to set DNS for a given interface
set_dns() {
    local interface=$1
    local dns_servers=$2
    echo "Setting DNS for interface: $interface"
    networksetup -setdnsservers $interface $dns_servers

    if [ $? -eq 0 ]; then
        echo "DNS set for interface $interface."
    else
        echo "Failed to set DNS for interface $interface."
    fi
}

# Detect VPN tun interfaces with a default route
vpn_interfaces=$(netstat -nr | awk '/default/ && /utun/ {print $NF}')

if [ -z "$vpn_interfaces" ]; then
    echo "No VPN tun interfaces with a default route found."
    exit 1
fi

# Remove default gateway for detected VPN tun interfaces
for interface in $vpn_interfaces; do
    remove_default_gateway $interface
done

# Set DNS servers
for interface in $vpn_interfaces; do
    set_dns $interface "$dns_servers"
done

echo "VPN network configuration completed."
