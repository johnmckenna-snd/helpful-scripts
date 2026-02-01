#!/bin/bash

usage() {
    echo "Usage: $0 [--inline <ip_address> <interval>]"
    echo ""
    echo "Options:"
    echo "  --inline <ip> <interval>  Provide IP and interval as arguments"
    echo "  (no args)                 Interactive mode - prompts for input"
    echo ""
    echo "Example:"
    echo "  $0 --inline 8.8.8.8 5"
    exit 1
}

# Check for --inline mode
if [[ "$1" == "--inline" ]]; then
    if [[ -z "$2" || -z "$3" ]]; then
        echo "Error: --inline requires IP address and interval."
        usage
    fi
    ip_address="$2"
    interval="$3"
else
    # Interactive mode - Prompt for IP address
    read -p "Enter IP address to ping: " ip_address

    # Validate IP was entered
    if [[ -z "$ip_address" ]]; then
        echo "Error: No IP address provided."
        exit 1
    fi

    # Prompt for interval
    read -p "Enter ping interval in seconds: " interval
fi

# Validate interval is a positive number
if ! [[ "$interval" =~ ^[0-9]+\.?[0-9]*$ ]] || [[ $(echo "$interval <= 0" | bc -l) -eq 1 ]]; then
    echo "Error: Please enter a valid positive number for interval."
    exit 1
fi

echo "Pinging $ip_address every $interval seconds. Press Ctrl+C to stop."
echo "----------------------------------------"

# Ping loop
while true; do
    ping -c 1 "$ip_address"
    sleep "$interval"
done