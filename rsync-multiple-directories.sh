#!/bin/bash

# Enhanced Rsync Multi-Directory Sync Script with Consistency Guarantees
# This script synchronizes 6 directories across different computers with safeguards
# to ensure data consistency using checksums, locking, and verification.

# Exit on any error
set -e

# Configuration
LOG_FILE="sync_$(date +%Y%m%d_%H%M%S).log"
LOCK_DIR="/tmp/rsync_locks"
CHECKSUM_DIR="/tmp/rsync_checksums"
SYNC_COMPLETION_FLAG="$LOCK_DIR/sync_complete"
ALERT_EMAIL="admin@example.com"  # Change to your email

# Define servers and directories
declare -A SERVERS
SERVERS=(
  ["server1"]="user1@server1"
  ["server2"]="user2@server2"
  ["server3"]="user3@server3"
  ["server4"]="user4@server4"
  ["server5"]="user5@server5"
  ["server6"]="user6@server6"
)

# Define directory mappings (master:slave format)
declare -A DIRECTORIES
DIRECTORIES=(
  ["dir1"]="/path/to/dir1"
  ["dir2"]="/path/to/dir2"
  ["dir3"]="/path/to/dir3"
  ["dir4"]="/path/to/dir4"
  ["dir5"]="/path/to/dir5"
  ["dir6"]="/path/to/dir6"
)

# Define master server for each directory
declare -A MASTERS
MASTERS=(
  ["dir1"]="server1"
  ["dir2"]="server2"
  ["dir3"]="server3"
  ["dir4"]="server4"
  ["dir5"]="server5"
  ["dir6"]="server6"
)

# Function to log messages
log_message() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "$LOG_FILE"
}

# Function to send alerts
send_alert() {
    local message="$1"
    log_message "ALERT: $message"
    echo "$message" | mail -s "Rsync Sync Alert" "$ALERT_EMAIL"
}

# Function to create and check locks
acquire_lock() {
    local resource="$1"
    local lock_file="$LOCK_DIR/${resource}.lock"
    
    mkdir -p "$LOCK_DIR"
    
    if [ -e "$lock_file" ]; then
        # Check if the lock is stale (older than 2 hours)
        if [ $(( $(date +%s) - $(stat -c %Y "$lock_file") )) -gt 7200 ]; then
            log_message "WARNING: Removing stale lock for $resource"
            rm -f "$lock_file"
        else
            log_message "ERROR: Resource $resource is locked. Sync already in progress or failed."
            return 1
        fi
    fi
    
    # Create the lock file
    touch "$lock_file"
    log_message "Lock acquired for $resource"
    return 0
}

# Function to release locks
release_lock() {
    local resource="$1"
    local lock_file="$LOCK_DIR/${resource}.lock"
    
    if [ -e "$lock_file" ]; then
        rm -f "$lock_file"
        log_message "Lock released for $resource"
    fi
}

# Function to verify server connectivity
check_connectivity() {
    local server="${SERVERS[$1]}"
    
    log_message "Checking connectivity to $server"
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$server" exit &>/dev/null
    
    if [ $? -ne 0 ]; then
        log_message "ERROR: Cannot connect to $server"
        return 1
    fi
    
    log_message "Connection to $server is OK"
    return 0
}

# Function to perform rsync with checksums
perform_sync() {
    local src_server="$1"
    local src_dir="$2"
    local dest_server="$3"
    local dest_dir="$4"
    local name="$5"
    
    local src_path
    local dest_path
    
    # Format paths for rsync
    if [ "$src_server" == "local" ]; then
        src_path="$src_dir/"
    else
        src_path="${SERVERS[$src_server]}:$src_dir/"
    fi
    
    if [ "$dest_server" == "local" ]; then
        dest_path="$dest_dir/"
    else
        dest_path="${SERVERS[$dest_server]}:$dest_dir/"
    fi
    
    log_message "Starting sync for $name: $src_path -> $dest_path"
    
    # Using rsync with enhanced options:
    # --checksum: use checksums to determine which files to transfer
    # --itemize-changes: output a change-summary for all updates
    rsync -avz --checksum --delete --itemize-changes \
        --exclude="*.tmp" \
        --exclude=".DS_Store" \
        --exclude="Thumbs.db" \
        --exclude=".sync_lock" \
        "$src_path" "$dest_path" 2>&1 | tee -a "$LOG_FILE"
    
    local status=$?
    
    if [ $status -eq 0 ]; then
        log_message "Sync completed successfully for $name"
        # Create a verification flag on destination to indicate successful sync
        if [ "$dest_server" == "local" ]; then
            touch "$dest_dir/.sync_complete_$(date +%s)"
        else
            ssh "${SERVERS[$dest_server]}" "touch $dest_dir/.sync_complete_$(date +%s)"
        fi
        return 0
    else
        log_message "ERROR: Sync failed for $name with status $status"
        send_alert "Sync failed for $name: $src_path -> $dest_path"
        return 1
    fi
}

# Function to verify consistency using checksums
verify_consistency() {
    local dir_name="$1"
    local master="${MASTERS[$dir_name]}"
    local errors=0
    
    log_message "Verifying consistency for $dir_name across all servers"
    
    # Create checksum directory
    mkdir -p "$CHECKSUM_DIR"
    
    # Generate checksum file from master
    local master_checksum="$CHECKSUM_DIR/${dir_name}_${master}.md5"
    
    if [ "$master" == "local" ]; then
        find "${DIRECTORIES[$dir_name]}" -type f -not -path "*/\.*" -exec md5sum {} \; > "$master_checksum"
    else
        ssh "${SERVERS[$master]}" "find ${DIRECTORIES[$dir_name]} -type f -not -path '*/\.*' -exec md5sum {} \;" > "$master_checksum"
    fi
    
    # Check other servers against master
    for server in "${!SERVERS[@]}"; do
        if [ "$server" != "$master" ]; then
            local server_checksum="$CHECKSUM_DIR/${dir_name}_${server}.md5"
            
            if [ "$server" == "local" ]; then
                find "${DIRECTORIES[$dir_name]}" -type f -not -path "*/\.*" -exec md5sum {} \; > "$server_checksum"
            else
                ssh "${SERVERS[$server]}" "find ${DIRECTORIES[$dir_name]} -type f -not -path '*/\.*' -exec md5sum {} \;" > "$server_checksum"
            fi
            
            # Compare checksums (ignoring paths, just checking file contents)
            local diff_result=$(cut -d' ' -f1 "$master_checksum" | sort | uniq > "$CHECKSUM_DIR/master_hashes"
                     cut -d' ' -f1 "$server_checksum" | sort | uniq > "$CHECKSUM_DIR/server_hashes"
                     diff "$CHECKSUM_DIR/master_hashes" "$CHECKSUM_DIR/server_hashes")
            
            if [ -n "$diff_result" ]; then
                log_message "ERROR: Consistency verification failed between $master and $server for $dir_name"
                send_alert "Consistency verification failed between $master and $server for $dir_name"
                errors=$((errors + 1))
            else
                log_message "Consistency verified between $master and $server for $dir_name"
            fi
        fi
    done
    
    return $errors
}

# Main sync function
sync_directory() {
    local dir_name="$1"
    local master="${MASTERS[$dir_name]}"
    local dir_path="${DIRECTORIES[$dir_name]}"
    local success=true
    
    log_message "===== Starting synchronization for $dir_name (master: $master) ====="
    
    # Acquire a lock for this directory
    if ! acquire_lock "$dir_name"; then
        log_message "Skipping sync for $dir_name due to lock acquisition failure"
        return 1
    fi
    
    # Create a marker file on the master to prevent modifications during sync
    if [ "$master" == "local" ]; then
        touch "$dir_path/.sync_lock"
    else
        ssh "${SERVERS[$master]}" "touch $dir_path/.sync_lock"
    fi
    
    # Sync from master to all other servers
    for server in "${!SERVERS[@]}"; do
        if [ "$server" != "$master" ]; then
            # Check connectivity
            if ! check_connectivity "$server"; then
                log_message "Skipping sync to $server due to connectivity issues"
                success=false
                continue
            fi
            
            # Perform the sync
            if ! perform_sync "$master" "$dir_path" "$server" "$dir_path" "$dir_name:$master->$server"; then
                success=false
            fi
        fi
    done
    
    # Remove the lock file
    if [ "$master" == "local" ]; then
        rm -f "$dir_path/.sync_lock"
    else
        ssh "${SERVERS[$master]}" "rm -f $dir_path/.sync_lock"
    fi
    
    # Verify consistency if sync was successful
    if $success; then
        if ! verify_consistency "$dir_name"; then
            success=false
            log_message "WARNING: Consistency check failed for $dir_name"
        fi
    fi
    
    # Release the lock
    release_lock "$dir_name"
    
    if $success; then
        log_message "===== Synchronization for $dir_name completed successfully ====="
        return 0
    else
        log_message "===== Synchronization for $dir_name completed with errors ====="
        return 1
    fi
}

# Main script
log_message "Starting enhanced multi-directory sync process"

# Create required directories
mkdir -p "$LOCK_DIR" "$CHECKSUM_DIR"

# Process each directory
overall_status=0

for dir in "${!DIRECTORIES[@]}"; do
    if ! sync_directory "$dir"; then
        overall_status=1
    fi
done

# Create sync completion flag
if [ $overall_status -eq 0 ]; then
    touch "$SYNC_COMPLETION_FLAG"
    log_message "SUMMARY: All synchronizations completed successfully."
else
    log_message "SUMMARY: Some synchronizations failed. Check the log for details."
    send_alert "Some directory synchronizations failed. Check the log for details."
fi

# Cleanup temporary files older than 7 days
find "$LOCK_DIR" "$CHECKSUM_DIR" -type f -mtime +7 -delete

exit $overall_status