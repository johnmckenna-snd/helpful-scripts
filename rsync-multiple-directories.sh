#!/bin/bash

# Array of all machines (including localhost)
MACHINES=(
    "localhost"
    "user1@server1.example.com"
    "user2@server2.example.com" 
    "admin@192.168.1.100"
)

# Array of folders to sync (local paths)
FOLDERS=(
    "/home/user/documents/"
    "/home/user/projects/"
    "/opt/shared/"
)

# Rsync options:
# -a: archive mode (preserves permissions, timestamps, etc.)
# -v: verbose output
# -z: compress data during transfer
# -u: update (skip files that are newer on the receiver)
# --exclude: exclude common files you don't want to sync
RSYNC_OPTS="-avzu --exclude='.git/' --exclude='*.tmp' --exclude='*.log'"

echo "Starting bidirectional multi-machine sync..."
echo "============================================="

# Function to sync between two machines
sync_machines() {
    local source_machine=$1
    local dest_machine=$2
    local folder=$3
    
    if [ "$source_machine" = "$dest_machine" ]; then
        return 0  # Skip syncing machine to itself
    fi
    
    folder_name=$(basename "$folder")
    
    if [ "$source_machine" = "localhost" ]; then
        # Local to remote
        echo "    $source_machine → $dest_machine"
        rsync $RSYNC_OPTS "$folder" "$dest_machine:~/$folder_name/"
    elif [ "$dest_machine" = "localhost" ]; then
        # Remote to local
        echo "    $source_machine → $dest_machine"
        rsync $RSYNC_OPTS "$source_machine:~/$folder_name/" "$folder"
    else
        # Remote to remote (via localhost as intermediary)
        echo "    $source_machine → localhost → $dest_machine"
        temp_dir="/tmp/sync_$(basename "$folder")_$"
        mkdir -p "$temp_dir"
        rsync $RSYNC_OPTS "$source_machine:~/$folder_name/" "$temp_dir/"
        rsync $RSYNC_OPTS "$temp_dir/" "$dest_machine:~/$folder_name/"
        rm -rf "$temp_dir"
    fi
}

# Main sync loop - sync all machines with all other machines
for folder in "${FOLDERS[@]}"; do
    echo "Syncing folder: $folder"
    echo "========================"
    
    # Check if local folder exists
    if [ "$folder" != "localhost" ] && [ ! -d "$folder" ]; then
        echo "  WARNING: Local folder $folder does not exist, creating..."
        mkdir -p "$folder"
    fi
    
    # First pass: everyone syncs TO localhost (collect all changes)
    echo "  Phase 1: Collecting changes to localhost"
    for source_machine in "${MACHINES[@]}"; do
        if [ "$source_machine" != "localhost" ]; then
            if sync_machines "$source_machine" "localhost" "$folder"; then
                echo "    ✓ Collected from $source_machine"
            else
                echo "    ✗ Failed to collect from $source_machine"
            fi
        fi
    done
    
    echo ""
    
    # Second pass: localhost syncs TO everyone (distribute all changes)
    echo "  Phase 2: Distributing changes from localhost"
    for dest_machine in "${MACHINES[@]}"; do
        if [ "$dest_machine" != "localhost" ]; then
            if sync_machines "localhost" "$dest_machine" "$folder"; then
                echo "    ✓ Distributed to $dest_machine"
            else
                echo "    ✗ Failed to distribute to $dest_machine"
            fi
        fi
    done
    
    echo ""
    
    # Third pass: Final cross-sync to catch any remaining differences
    echo "  Phase 3: Final cross-synchronization"
    for source_machine in "${MACHINES[@]}"; do
        for dest_machine in "${MACHINES[@]}"; do
            if [ "$source_machine" != "$dest_machine" ] && [ "$source_machine" != "localhost" ] && [ "$dest_machine" != "localhost" ]; then
                if sync_machines "$source_machine" "$dest_machine" "$folder"; then
                    echo "    ✓ Cross-synced $source_machine → $dest_machine"
                else
                    echo "    ✗ Failed cross-sync $source_machine → $dest_machine"
                fi
            fi
        done
    done
    
    echo ""
    echo "----------------------------------------"
done

echo "Bidirectional sync complete!"
echo "============================"

# Verification: Check file counts on all machines
echo "Verification (file counts):"
echo "============================"
for folder in "${FOLDERS[@]}"; do
    # Create safe remote path name
    remote_folder_path=$(echo "$folder" | sed 's|^/||' | sed 's|/$||' | tr '/' '_')
    echo "Folder: $folder (remote: sync_$remote_folder_path)"
    
    for machine in "${MACHINES[@]}"; do
        if [ "$machine" = "localhost" ]; then
            count=$(find "$folder" -type f 2>/dev/null | wc -l)
            echo "  $machine: $count files"
        else
            count=$(ssh "$machine" "find ~/sync_$remote_folder_path -type f 2>/dev/null | wc -l" 2>/dev/null)
            if [ $? -eq 0 ]; then
                echo "  $machine: $count files"
            else
                echo "  $machine: Could not check"
            fi
        fi
    done
    echo ""
done