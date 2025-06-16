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

# Bidirectional Multi-Machine Sync Script Documentation

## Overview

This bash script provides true bidirectional synchronization of directories across multiple machines using rsync over SSH. Unlike traditional one-way sync solutions, this script ensures all specified directories contain the union of files from all machines, with newer files taking precedence during conflicts. The script uses a three-phase approach with the local machine acting as a coordination hub.

## How It Works

The script employs a **hub-and-spoke** model with three synchronization phases:

1. **Collection Phase**: All remote machines sync TO localhost (gathering all changes)
2. **Distribution Phase**: Localhost syncs TO all remote machines (distributing the complete set)  
3. **Cross-Sync Phase**: Final direct sync between remote machines for consistency

This approach ensures that files created or modified on any machine will propagate to all other machines, while preserving existing files and handling conflicts intelligently.

## Prerequisites

- **rsync**: Must be installed on all machines (local and remote)
- **SSH access**: Password-less SSH access from localhost to all remote machines
- **Bash shell**: Compatible with bash 4.0+
- **Network connectivity**: Stable network connection from localhost to all target machines
- **Permissions**: Write access to destination directories on all machines
- **Localhost coordination**: Script must run on the machine designated as "localhost"

## SSH Key Setup

The script requires passwordless SSH access from your localhost to all remote machines.

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

For each machine in your `MACHINES` array (except localhost), copy your public key:

```bash
# Method 1: Using ssh-copy-id (recommended)
ssh-copy-id user@remote-host

# Method 2: Manual copy
cat ~/.ssh/id_rsa.pub | ssh user@remote-host "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### Test SSH Connection

Verify passwordless access works for all remote machines:

```bash
ssh user@remote-host "echo 'Connection successful'"
```

### Automated SSH Key Setup Script

Here's a helper script to automate SSH key setup for all your machines:

```bash
#!/bin/bash

# SSH Key Setup Script for Bidirectional Multi-Machine Sync

# Array of remote machines (exclude localhost)
REMOTE_MACHINES=(
    "user1@server1.example.com"
    "user2@server2.example.com" 
    "admin@192.168.1.100"
)

echo "Setting up SSH keys for bidirectional sync..."
echo "============================================="

# Check if SSH key exists
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "No SSH key found. Generating new key..."
    ssh-keygen -t rsa -b 4096 -C "$(whoami)@$(hostname)-sync"
    echo "SSH key generated successfully!"
fi

echo "Public key to be distributed:"
echo "-----------------------------"
cat ~/.ssh/id_rsa.pub
echo ""

# Copy key to each remote machine
for machine in "${REMOTE_MACHINES[@]}"; do
    echo "Setting up key for: $machine"
    
    if ssh-copy-id "$machine" 2>/dev/null; then
        echo "  ✓ Key copied successfully to $machine"
        
        # Test connection
        if ssh "$machine" "echo 'Test connection successful'" >/dev/null 2>&1; then
            echo "  ✓ Connection test passed for $machine"
            
            # Test rsync
            if ssh "$machine" "command -v rsync" >/dev/null 2>&1; then
                echo "  ✓ rsync available on $machine"
            else
                echo "  ⚠ rsync not found on $machine - please install it"
            fi
        else
            echo "  ✗ Connection test failed for $machine"
        fi
    else
        echo "  ✗ Failed to copy key to $machine"
        echo "    Manual setup required:"
        echo "    cat ~/.ssh/id_rsa.pub | ssh $machine 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'"
    fi
    echo ""
done

echo "SSH key setup complete!"
echo ""
echo "Next steps:"
echo "1. Verify all remote machines have rsync installed"
echo "2. Configure the MACHINES array in the sync script"
echo "3. Configure the FOLDERS array with your directories"
echo "4. Run the sync script from this localhost machine"
```

## Script Configuration

### 1. Machines Array

Edit the `MACHINES` array to include localhost and all target machines:

```bash
MACHINES=(
    "localhost"                    # Must be first - acts as coordination hub
    "username@server1.example.com"
    "admin@192.168.1.100"
    "user@myserver.com"
)
```

**Important notes**:
- **Keep "localhost" as the first entry** - it coordinates all sync operations
- **Run the script from the localhost machine only**
- Use format `username@hostname_or_ip` for remote machines
- Ensure all remote machines are accessible via SSH from localhost

### 2. Folders Array

Edit the `FOLDERS` array to specify which directories to sync:

```bash
FOLDERS=(
    "/home/user/documents/"
    "/home/user/projects/"
    "/opt/shared/"
    "/var/www/html/"
)
```

**Configuration notes**:
- Use absolute paths for consistency
- Include trailing slash for directories
- Directories will be created if they don't exist
- Remote machines will store folders in the user's home directory (`~/folder_name/`)

### 3. Rsync Options

The script uses these rsync options optimized for bidirectional sync:

```bash
RSYNC_OPTS="-avzu --exclude='.git/' --exclude='*.tmp' --exclude='*.log'"
```

**Option explanations**:
- `-a`: Archive mode (preserves permissions, timestamps, ownership)
- `-v`: Verbose output for detailed logging
- `-z`: Compress data during transfer (faster over slow networks)
- `-u`: Update mode (only transfer files newer than destination)
- `--exclude`: Skip specified files/patterns

**Note**: The `--delete` option is intentionally omitted to prevent data loss during bidirectional sync.

### 4. Custom Exclusions

Add more exclusions for files you don't want to sync:

```bash
RSYNC_OPTS="-avzu \
    --exclude='.git/' \
    --exclude='*.tmp' \
    --exclude='*.log' \
    --exclude='node_modules/' \
    --exclude='.DS_Store' \
    --exclude='*.swp' \
    --exclude='.cache/' \
    --exclude='thumbs.db'"
```

## Usage

### Basic Usage

1. **Set up SSH keys** using the helper script above
2. **Configure the script** with your machines and folders
3. **Make executable**:
   ```bash
   chmod +x bidirectional_sync.sh
   ```
4. **Run from localhost**:
   ```bash
   ./bidirectional_sync.sh
   ```

### Important Usage Notes

- **Always run from localhost** - the machine listed as "localhost" in the MACHINES array
- **Initial sync may take longer** as it processes all files from all machines
- **Subsequent syncs are faster** due to rsync's incremental nature
- **Monitor the output** for any failed transfers or errors

### Scheduling with Cron

To run automatic bidirectional sync:

```bash
# Edit crontab on the localhost machine
crontab -e

# Run every 2 hours (recommended for bidirectional sync)
0 */2 * * * /path/to/bidirectional_sync.sh >> /var/log/bidirectional-sync.log 2>&1

# Run daily at 3 AM for less frequent syncing
0 3 * * * /path/to/bidirectional_sync.sh >> /var/log/bidirectional-sync.log 2>&1

# Run every 30 minutes for high-frequency syncing (use with caution)
*/30 * * * * /path/to/bidirectional_sync.sh >> /var/log/bidirectional-sync.log 2>&1
```

**Cron considerations**:
- Bidirectional sync is more resource-intensive than one-way sync
- Don't run too frequently to avoid conflicts with long-running syncs
- Monitor logs to ensure syncs complete successfully
- Consider network usage during business hours

## Script Output

The script provides detailed three-phase output:

```
Starting bidirectional multi-machine sync...
=============================================

Syncing folder: /home/user/documents/
========================
  Phase 1: Collecting changes to localhost
    user1@server1.example.com → localhost
    ✓ Collected from user1@server1.example.com
    user2@server2.example.com → localhost
    ✓ Collected from user2@server2.example.com

  Phase 2: Distributing changes from localhost
    localhost → user1@server1.example.com
    ✓ Distributed to user1@server1.example.com
    localhost → user2@server2.example.com
    ✓ Distributed to user2@server2.example.com

  Phase 3: Final cross-synchronization
    user1@server1.example.com → user2@server2.example.com
    ✓ Cross-synced user1@server1.example.com → user2@server2.example.com
    user2@server2.example.com → user1@server1.example.com
    ✓ Cross-synced user2@server2.example.com → user1@server1.example.com

----------------------------------------

Bidirectional sync complete!
============================
Verification (file counts):
============================
Folder: documents
  localhost: 127 files
  user1@server1.example.com: 127 files
  user2@server2.example.com: 127 files

Folder: projects
  localhost: 84 files
  user1@server1.example.com: 84 files
  user2@server2.example.com: 84 files
```

## Conflict Resolution

The script handles file conflicts using these rules:

### Timestamp-Based Resolution
- **Newer files win**: Files with more recent modification times overwrite older versions
- **Rsync `-u` flag**: Ensures only newer files are transferred
- **No data loss**: Original files are preserved if they're newer

### Conflict Scenarios

1. **Same file modified on multiple machines**:
   - Result: The version with the most recent timestamp wins
   - Other versions are overwritten

2. **File exists on some machines but not others**:
   - Result: File is copied to all machines
   - No files are deleted

3. **Directory structure differences**:
   - Result: Union of all directory structures
   - All directories and subdirectories are preserved

## Troubleshooting

### Common Issues

1. **"Permission denied" errors**
   ```
   Symptoms: rsync fails with permission denied
   Solutions: 
   - Verify SSH key setup is correct
   - Check file/directory permissions on remote machines
   - Ensure user has write access to destination directories
   ```

2. **"Connection refused" errors**
   ```
   Symptoms: Cannot connect to remote machine
   Solutions:
   - Verify SSH service is running on remote machine
   - Check firewall settings allow SSH (port 22)
   - Verify hostname/IP address is correct
   ```

3. **"rsync: command not found"**
   ```
   Symptoms: rsync not available on remote machine
   Solutions:
   - Install rsync: sudo apt-get install rsync (Ubuntu/Debian)
   - Install rsync: sudo yum install rsync (CentOS/RHEL)
   - Install rsync: sudo dnf install rsync (Fedora)
   ```

4. **Sync takes too long**
   ```
   Symptoms: Script runs for hours
   Solutions:
   - Check network connectivity and speed
   - Reduce folder sizes by adding exclusions
   - Run initial sync during off-peak hours
   - Consider running phases separately for large datasets
   ```

5. **File count mismatches after sync**
   ```
   Symptoms: Different file counts on different machines
   Solutions:
   - Check for sync errors in the output
   - Verify all machines completed successfully
   - Run the script again (rsync is idempotent)
   - Check for permission issues preventing file creation
   ```

### Debug Mode

For troubleshooting, enable debug options:

```bash
# Add to rsync options for debugging
RSYNC_OPTS="-avzu --dry-run --stats --progress --exclude='.git/' --exclude='*.tmp' --exclude='*.log'"
```

Debug option explanations:
- `--dry-run`: Shows what would be transferred without actually doing it
- `--stats`: Provides detailed transfer statistics
- `--progress`: Shows progress during transfer

### Manual Testing

Test individual components:

```bash
# Test SSH connection to each machine
for machine in user1@server1.example.com user2@server2.example.com; do
    echo "Testing $machine..."
    ssh "$machine" "echo 'Connection OK'"
done

# Test rsync to a single machine
rsync -avzu --dry-run /local/folder/ user@remote-host:~/folder/

# Check if directories exist on remote machines
ssh user@remote-host "ls -la ~/"

# Test bidirectional sync on a small test folder
mkdir /tmp/test_sync
echo "test file" > /tmp/test_sync/test.txt
# Then modify FOLDERS temporarily to use /tmp/test_sync/
```

### Log Analysis

Enable comprehensive logging:

```bash
#!/bin/bash
# Add at the beginning of the script

LOG_DIR="/var/log/bidirectional-sync"
LOG_FILE="$LOG_DIR/sync-$(date +%Y%m%d-%H%M%S).log"

# Create log directory
mkdir -p "$LOG_DIR"

# Redirect all output to log file and console
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "Sync started at $(date)"
echo "Log file: $LOG_FILE"
```

## Security Considerations

### SSH Security
1. **Use strong SSH keys**: Minimum 2048-bit RSA or ED25519 keys
2. **Protect private keys**: Use passphrases and proper file permissions (600)
3. **Limit SSH access**: Configure SSH to only allow key-based authentication
4. **Regular key rotation**: Update SSH keys periodically

### Network Security
1. **VPN usage**: Use VPN for syncing over public networks
2. **Firewall rules**: Restrict SSH access to known IP addresses
3. **Monitor connections**: Log and monitor SSH connections
4. **Use non-standard SSH ports**: Consider changing SSH from port 22

### File Security
1. **Sensitive data exclusions**: Exclude sensitive files from sync
2. **Permission preservation**: Verify file permissions are appropriate after sync
3. **Backup strategy**: Maintain separate backups of critical data
4. **Audit trail**: Keep logs of all sync operations

## Best Practices

### Pre-Sync Preparation
1. **Backup critical data** before first bidirectional sync
2. **Test with small datasets** initially
3. **Use `--dry-run`** to preview changes
4. **Document your setup** including machine purposes and folder contents

### Operational Best Practices
1. **Monitor sync frequency**: Don't run too often to avoid conflicts
2. **Check logs regularly**: Review sync logs for errors or issues
3. **Validate after sync**: Verify file counts and critical files exist
4. **Handle large files carefully**: Consider excluding very large files that change frequently

### Maintenance
1. **Regular SSH key updates**: Rotate keys according to security policy
2. **Clean up temporary files**: Remove rsync temporary files periodically
3. **Monitor disk space**: Ensure all machines have adequate free space
4. **Update exclusion patterns**: Regularly review and update file exclusions

### Performance Optimization
1. **Network timing**: Run large syncs during off-peak hours
2. **Exclude unnecessary files**: Be aggressive with exclusion patterns
3. **Monitor resource usage**: Check CPU, memory, and network usage during sync
4. **Consider partial syncs**: For very large datasets, consider syncing subsets

## Advanced Configuration

### Custom Remote Paths

To sync to different paths on different machines:

```bash
# Modify the sync_machines function to handle custom paths
sync_machines() {
    local source_machine=$1
    local dest_machine=$2
    local folder=$3
    
    # Define custom remote paths per machine
    case "$dest_machine" in
        "user1@server1.example.com")
            remote_path="/var/data/$(basename "$folder")"
            ;;
        "admin@192.168.1.100")
            remote_path="/opt/shared/$(basename "$folder")"
            ;;
        *)
            remote_path="~/$(basename "$folder")"
            ;;
    esac
    
    # Use $remote_path instead of ~/folder_name/
}
```

### Parallel Phase Execution

For faster syncing with many machines:

```bash
# Modify phases to run in parallel
echo "  Phase 1: Collecting changes to localhost"
for source_machine in "${MACHINES[@]}"; do
    if [ "$source_machine" != "localhost" ]; then
        (
            if sync_machines "$source_machine" "localhost" "$folder"; then
                echo "    ✓ Collected from $source_machine"
            else
                echo "    ✗ Failed to collect from $source_machine"
            fi
        ) &
    fi
done
wait  # Wait for all background jobs to complete
```

### Machine-Specific Configuration

Handle different machine types:

```bash
# Define machine types
PRODUCTION_MACHINES=("user@prod1.example.com" "user@prod2.example.com")
STAGING_MACHINES=("user@staging.example.com")
DEVELOPMENT_MACHINES=("localhost" "user@dev.example.com")

# Sync production machines more conservatively
if [[ " ${PRODUCTION_MACHINES[@]} " =~ " ${dest_machine} " ]]; then
    RSYNC_OPTS="$RSYNC_OPTS --backup --backup-dir=backup-$(date +%Y%m%d)"
fi
```

### Notification System

Add notifications for sync completion:

```bash
# At the end of the script
SYNC_SUCCESS=true  # Set based on sync results

if [ "$SYNC_SUCCESS" = true ]; then
    echo "All syncs completed successfully" | mail -s "Bidirectional Sync Success" admin@example.com
else
    echo "Some syncs failed - check logs" | mail -s "Bidirectional Sync Failed" admin@example.com
fi
```

This enhanced bidirectional sync script provides a robust solution for keeping multiple machines synchronized while preserving all data and handling conflicts intelligently.