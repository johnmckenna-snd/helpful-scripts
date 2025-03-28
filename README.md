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

## Enhanced Rsync Multi-Directory Sync

### Overview
A robust synchronization script that ensures data consistency across multiple servers using rsync with checksums, file locking, and verification.

### Prerequisites
- Bash shell environment
- Rsync installed on all servers
- SSH key-based authentication configured between servers
- Proper read/write permissions on all directories

### Configuration

#### Server Configuration
Edit the `SERVERS` array to define your server connections:
```bash
SERVERS=(
  ["server1"]="user1@server1"
  ["server2"]="user2@server2"
  # Add all servers here
)
```

#### Directory Configuration
Configure directories to sync:
```bash
DIRECTORIES=(
  ["dir1"]="/path/to/dir1"
  ["dir2"]="/path/to/dir2"
  # Add all directories here
)
```

#### Master Server Configuration
Define which server is the master for each directory:
```bash
MASTERS=(
  ["dir1"]="server1"
  ["dir2"]="server2"
  # Assign a master to each directory
)
```

#### Alert Configuration
Set email for alert notifications:
```bash
ALERT_EMAIL="admin@example.com"
```

### Basic Usage

#### Running the Script
```bash
./rsync_sync.sh
```

#### Scheduling with Cron
Add to crontab to run automatically:
```bash
# Run every day at 2 AM
0 2 * * * /path/to/rsync_sync.sh
```

### Command-Line Options

| Option | Description |
|--------|-------------|
| `-v`   | Verbose mode (more detailed logs) |
| `-n`   | Dry run (no actual changes made) |
| `-d DIR` | Sync only specific directory |

Example:
```bash
./rsync_sync.sh -v -d dir1
```

### Log Files
- Main log: `sync_YYYYMMDD_HHMMSS.log`
- Checksums: `/tmp/rsync_checksums/`
- Lock files: `/tmp/rsync_locks/`

### Troubleshooting

#### Common Issues
1. **Lock file not clearing**: Delete manually from `/tmp/rsync_locks/`
2. **SSH connection failures**: Verify SSH keys are properly configured
3. **Checksum mismatch**: Review the specific files in checksum logs

#### Manual Verification
Run a consistency check on a specific directory:
```bash
./rsync_sync.sh --verify-only -d dir1
```

### Security Considerations
- Uses SSH for secure transfers
- Requires key-based authentication
- No passwords stored in script
- Limited to defined servers and directories

### Performance Optimization
- Run during low-traffic periods
- Consider bandwidth limitations
- Exclude temporary or cache files when necessary