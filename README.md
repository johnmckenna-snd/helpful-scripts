# Helpful Network Scripts

Yeet. These are mostly AI written so ya know can it be trusted?

## Local Websocket Monitor

This script provides real-time monitoring of local network statistics relevant to WebSocket connections. It's particularly useful for troubleshooting connection issues, performance problems, and network-related bugs in WebSocket applications.

### Installation

1. Pull down this repo

2. Make it executable:
```bash
chmod +x local_websocket_monitor.sh
```

## Usage

Run the script with sudo privileges:
```bash
sudo ./local_websocket_monitor.sh [-i interval]
```

Options:
- `-i, --interval`: Refresh interval in seconds (default: 3)

### Monitored Metrics

#### TCP Retransmission Statistics
Shows counts of:
- Retransmitted segments
- Timeout events
- Failed connection attempts

This helps identify connection stability issues and packet loss.

#### TCP Memory Usage
Displays current TCP memory allocation:
- Current usage
- Warning threshold
- Maximum limit

High memory usage might indicate buffer bloat or connection handling issues.

#### Network Interface Statistics
For your primary network interface:
- RX/TX bytes (throughput)
- RX/TX errors
- RX/TX dropped packets

Helps identify network congestion and hardware/driver issues.

#### TCP Connection States
Count of connections in each state:
- ESTABLISHED
- TIME-WAIT
- CLOSE-WAIT
- etc.

Unusual patterns here can indicate connection handling problems.

#### Current WebSocket-like Connections
Lists active connections on common WebSocket ports (80, 443):
- Local and remote addresses
- Connection state
- Queue sizes

#### Socket Buffer Status
Shows for each connection:
- Send/Receive queue sizes
- Window sizes
- Congestion state

Large queues or small windows can indicate performance problems.

#### System Buffer Parameters
Global system settings for:
- Maximum receive buffer
- Maximum send buffer
- Application memory limits

## Interpreting the Output

### Common Issues

1. **High Retransmission Counts**
   - Indicates packet loss
   - Check network quality and firewall settings

2. **Growing Send/Receive Queues**
   - Application not reading/writing fast enough
   - Possible bandwidth or processing bottleneck

3. **Many TIME_WAIT Connections**
   - Normal for busy servers
   - May indicate connection cycling issues

4. **Dropped Packets**
   - Network interface or driver issues
   - System buffer limits too low

### Troubleshooting Tips

1. If you see high retransmission counts:
   - Check network connectivity
   - Verify firewall rules
   - Monitor for packet loss

2. For buffer issues:
   - Review application read/write patterns
   - Consider increasing system buffer limits
   - Check application threading model

3. For connection state problems:
   - Verify connection timeout settings
   - Check keepalive configuration
   - Review connection handling code

# Multi-Machine Sync Script Documentation

## Overview

This bash script synchronizes directories across multiple remote machines using rsync over SSH. It ensures all specified directories remain identical across all target machines by transferring only changed or new files and optionally removing files that no longer exist on the source.

## Prerequisites

- **rsync**: Must be installed on all machines (local and remote)
- **SSH access**: Password-less SSH access to all remote machines
- **Bash shell**: Compatible with bash 4.0+
- **Network connectivity**: Stable network connection to all target machines
- **Permissions**: Write access to destination directories on remote machines

## SSH Key Setup

Before using the sync script, you must set up SSH key authentication for passwordless access to remote machines.

### Generate SSH Key Pair

```bash
# Generate a new SSH key pair (if you don't have one)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# When prompted:
# - Press Enter to accept default file location (~/.ssh/id_rsa)
# - Enter a passphrase (optional but recommended)
# - Confirm the passphrase
```

### Copy Public Key to Remote Machines

For each machine in your `DESTINATIONS` array, copy your public key:

```bash
# Method 1: Using ssh-copy-id (recommended)
ssh-copy-id user@remote-host

# Method 2: Manual copy
cat ~/.ssh/id_rsa.pub | ssh user@remote-host "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### Test SSH Connection

Verify passwordless access works:

```bash
ssh user@remote-host "echo 'Connection successful'"
```

### SSH Key Setup Script

Here's a helper script to automate SSH key setup:

```bash
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
```

## Script Configuration

### 1. Destinations Array

Edit the `DESTINATIONS` array to include your target machines:

```bash
DESTINATIONS=(
    "username@server1.example.com"
    "admin@192.168.1.100"
    "user@myserver.com"
)
```

**Format**: `username@hostname_or_ip`

### 2. Folders Array

Edit the `FOLDERS` array to specify which directories to sync:

```bash
FOLDERS=(
    "/home/user/documents/"
    "/home/user/projects/"
    "/opt/shared/"
)
```

**Notes**:
- Use absolute paths
- Include trailing slash for directories
- Ensure source directories exist before running

### 3. Rsync Options

The script uses these rsync options:

```bash
RSYNC_OPTS="-avz --delete --exclude='.git/' --exclude='*.tmp' --exclude='*.log'"
```

**Option explanations**:
- `-a`: Archive mode (preserves permissions, timestamps, ownership)
- `-v`: Verbose output
- `-z`: Compress data during transfer
- `--delete`: Remove files on destination that don't exist on source
- `--exclude`: Skip specified files/patterns

### 4. Custom Exclusions

Add more exclusions as needed:

```bash
RSYNC_OPTS="-avz --delete \
    --exclude='.git/' \
    --exclude='*.tmp' \
    --exclude='*.log' \
    --exclude='node_modules/' \
    --exclude='.DS_Store' \
    --exclude='*.swp'"
```

## Usage

### Basic Usage

1. Make the script executable:
   ```bash
   chmod +x sync_script.sh
   ```

2. Run the script:
   ```bash
   ./sync_script.sh
   ```

### Scheduling with Cron

To run the sync automatically, add to crontab:

```bash
# Edit crontab
crontab -e

# Add entry to run every hour
0 * * * * /path/to/sync_script.sh >> /var/log/sync.log 2>&1

# Add entry to run daily at 2 AM
0 2 * * * /path/to/sync_script.sh >> /var/log/sync.log 2>&1
```

## Script Output

The script provides detailed output:

```
Starting multi-machine sync...
================================
Syncing to: user@server1.example.com
------------------------
  Syncing folder: /home/user/documents/
    ✓ Successfully synced /home/user/documents/ to user@server1.example.com
  Syncing folder: /home/user/projects/
    ✓ Successfully synced /home/user/projects/ to user@server1.example.com

Syncing to: admin@192.168.1.100
------------------------
  Syncing folder: /home/user/documents/
    ✓ Successfully synced /home/user/documents/ to admin@192.168.1.100
  Syncing folder: /home/user/projects/
    ✓ Successfully synced /home/user/projects/ to admin@192.168.1.100

Sync complete!
================================
Verification (file counts):
Files on user@server1.example.com:
  42 files in documents
  156 files in projects

Files on admin@192.168.1.100:
  42 files in documents
  156 files in projects
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```
   Solution: Ensure SSH key is properly set up and user has write permissions
   ```

2. **Connection Refused**
   ```
   Solution: Verify SSH service is running on remote machine and firewall allows SSH
   ```

3. **Rsync Command Not Found**
   ```
   Solution: Install rsync on remote machine (apt-get install rsync / yum install rsync)
   ```

4. **File/Directory Not Found**
   ```
   Solution: Verify source directories exist and paths are correct
   ```

### Debug Mode

For debugging, modify rsync options:

```bash
RSYNC_OPTS="-avz --delete --dry-run --stats"
```

- `--dry-run`: Shows what would be transferred without actually doing it
- `--stats`: Provides detailed transfer statistics

### Manual Testing

Test individual components:

```bash
# Test SSH connection
ssh user@remote-host "echo 'Connection OK'"

# Test rsync to single destination
rsync -avz --dry-run /local/folder/ user@remote-host:~/folder/

# Check remote directory
ssh user@remote-host "ls -la ~/folder/"
```

## Security Considerations

1. **SSH Key Protection**: Use passphrase-protected SSH keys
2. **Key Management**: Regularly rotate SSH keys
3. **Network Security**: Use VPN for syncing over public networks
4. **File Permissions**: Verify destination permissions are appropriate
5. **Logging**: Monitor sync logs for unauthorized access attempts

## Best Practices

1. **Backup Before Sync**: Always backup important data before first sync
2. **Test First**: Use `--dry-run` option to preview changes
3. **Monitor Logs**: Keep logs of sync operations
4. **Validate Destinations**: Verify all destinations are reachable before bulk operations
5. **Exclude Sensitive Files**: Use exclusion patterns for sensitive or temporary files
6. **Regular Maintenance**: Periodically review and update destination and folder lists

## Advanced Configuration

### Custom Remote Paths

To sync to different paths on different machines:

```bash
# Instead of using basename, specify full remote paths
rsync $RSYNC_OPTS "$folder" "$dest:/custom/path/$(basename "$folder")/"
```

### Parallel Execution

For faster syncing, run destinations in parallel:

```bash
# Add before the destination loop
for dest in "${DESTINATIONS[@]}"; do
    (
        # Existing sync logic here
    ) &
done
wait  # Wait for all background jobs to complete
```

### Logging Enhancement

Add comprehensive logging:

```bash
LOG_FILE="/var/log/multi-sync-$(date +%Y%m%d).log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1
```