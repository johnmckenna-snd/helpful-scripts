#!/bin/bash

# Check if required tools are installed
for cmd in ss netstat grep; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is not installed. Please install it first."
        exit 1
    fi
done

# Default refresh interval
INTERVAL=3

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Usage: $0 [-i interval]"
            exit 1
            ;;
    esac
done

# Function to clear screen and move cursor to top
clear_screen() {
    clear
    tput cup 0 0
}

# Function to print section header
print_header() {
    echo -e "\e[1;34m=== $1 ===\e[0m"
}

# Function to get TCP retransmission stats
get_retransmit_stats() {
    netstat -s | grep -i "retransmit\|timeout\|failed" | sed 's/^[[:space:]]*//'
}

# Function to get TCP memory usage
get_tcp_memory() {
    cat /proc/net/tcp_mem 2>/dev/null || echo "TCP memory info not available"
}

# Function to get established WebSocket-like connections
get_websocket_connections() {
    # Look for established connections on common WebSocket ports and with typical WebSocket characteristics
    ss -tn state established '( sport = :443 or sport = :80 or dport = :443 or dport = :80 )'
}

# Function to get socket buffer status
get_socket_buffers() {
    ss -tmpe | grep -v "ESTAB\|State"
}

# Function to get network interface stats
get_interface_stats() {
    local interface=$(ip route get 8.8.8.8 2>/dev/null | grep -oP "dev \K\w+")
    if [[ ! -z "$interface" ]]; then
        echo "Primary Interface ($interface):"
        cat "/sys/class/net/$interface/statistics/rx_bytes" 2>/dev/null | \
            awk '{printf "  RX bytes: %.2f MB\n", $1/1024/1024}'
        cat "/sys/class/net/$interface/statistics/tx_bytes" 2>/dev/null | \
            awk '{printf "  TX bytes: %.2f MB\n", $1/1024/1024}'
        cat "/sys/class/net/$interface/statistics/rx_errors" 2>/dev/null | \
            awk '{printf "  RX errors: %d\n", $1}'
        cat "/sys/class/net/$interface/statistics/tx_errors" 2>/dev/null | \
            awk '{printf "  TX errors: %d\n", $1}'
        cat "/sys/class/net/$interface/statistics/rx_dropped" 2>/dev/null | \
            awk '{printf "  RX dropped: %d\n", $1}'
        cat "/sys/class/net/$interface/statistics/tx_dropped" 2>/dev/null | \
            awk '{printf "  TX dropped: %d\n", $1}'
    else
        echo "Could not determine primary interface"
    fi
}

# Function to get TCP connection states count
get_tcp_states() {
    ss -tan | awk 'NR>1 {print $1}' | sort | uniq -c | \
        awk '{printf "  %-10s : %d\n", $2, $1}'
}

# Main monitoring loop
while true; do
    clear_screen
    echo "Local Network Monitor for WebSocket Connections"
    echo "Refresh Interval: ${INTERVAL}s"
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "----------------------------------------"
    
    print_header "TCP Retransmission Statistics"
    get_retransmit_stats
    echo
    
    print_header "TCP Memory Usage"
    get_tcp_memory
    echo
    
    print_header "Network Interface Statistics"
    get_interface_stats
    echo
    
    print_header "TCP Connection States"
    get_tcp_states
    echo
    
    print_header "Current WebSocket-like Connections"
    get_websocket_connections
    echo
    
    print_header "Socket Buffer Status"
    get_socket_buffers
    echo
    
    print_header "System Buffer Parameters"
    sysctl -a 2>/dev/null | grep "net.core.*mem" | sed 's/^/  /'
    echo

    sleep "$INTERVAL"
done
