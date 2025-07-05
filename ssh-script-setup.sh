#!/bin/bash

# SSH Key Setup Script for Multi-Machine Sync

# Array of remote destinations (same as in sync script)
DESTINATIONS=(
    "user1@server1.example.com"
    "user2@server2.example.com" 
    "admin@192.168.1.100"
)

echo "Setting up SSH keys for passwordless access..."
echo "=============================================="

# Check if SSH key exists
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "No SSH key found. Generating new key..."
    ssh-keygen -t rsa -b 4096 -C "$(whoami)@$(hostname)"
    echo "SSH key generated successfully!"
fi

# Copy key to each destination
for dest in "${DESTINATIONS[@]}"; do
    echo "Setting up key for: $dest"
    
    if ssh-copy-id "$dest" 2>/dev/null; then
        echo "  ✓ Key copied successfully to $dest"
        
        # Test connection
        if ssh "$dest" "echo 'Test connection successful'" >/dev/null 2>&1; then
            echo "  ✓ Connection test passed for $dest"
        else
            echo "  ✗ Connection test failed for $dest"
        fi
    else
        echo "  ✗ Failed to copy key to $dest"
        echo "    You may need to copy the key manually:"
        echo "    cat ~/.ssh/id_rsa.pub | ssh $dest 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'"
    fi
    echo ""
done

echo "SSH key setup complete!"