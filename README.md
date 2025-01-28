# Network Monitoring Scripts

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