#!/bin/bash
# Generate a named SSH key and set it up on the server

if [ $# -lt 3 ]; then
    echo "Usage: $0 <device-name> <user> <address>"
    echo "Example: $0 server-0014 admin 192.168.1.50"
    exit 1
fi

device="$1"
user="$2"
address="$3"
keyfile="$HOME/.ssh/id_rsa_$device"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Generate key if it doesn't exist
if [ ! -f "$keyfile" ]; then
    echo "Generating key: $keyfile"
    ssh-keygen -t rsa -b 4096 -f "$keyfile" -C "$device" -N ""
else
    echo "Key already exists: $keyfile"
fi

# Copy key to server
echo "Copying key to $user@$address..."
if ssh-copy-id -i "$keyfile" "$user@$address"; then
    echo "✓ Key copied"
    
    # Test connection
    if ssh -i "$keyfile" "$user@$address" "echo '✓ Connection successful'"; then
        echo ""
        echo "Done. Connect with:"
        echo "  ssh -i $keyfile $user@$address"
    fi
else
    echo "✗ Failed to copy key"
    exit 1
fi