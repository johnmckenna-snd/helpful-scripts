#!/bin/bash

# Array of remote destinations (user@host format)
DESTINATIONS=(
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
# --delete: delete files on destination that don't exist on source
# --exclude: exclude common files you don't want to sync
RSYNC_OPTS="-avz --delete --exclude='.git/' --exclude='*.tmp' --exclude='*.log'"

echo "Starting multi-machine sync..."
echo "================================"

# Loop through each destination
for dest in "${DESTINATIONS[@]}"; do
    echo "Syncing to: $dest"
    echo "------------------------"
    
    # Loop through each folder for current destination
    for folder in "${FOLDERS[@]}"; do
        echo "  Syncing folder: $folder"
        
        # Check if local folder exists
        if [ ! -d "$folder" ]; then
            echo "    WARNING: Local folder $folder does not exist, skipping..."
            continue
        fi
        
        # Extract folder name for remote path
        folder_name=$(basename "$folder")
        
        # Sync folder to remote destination
        if rsync $RSYNC_OPTS "$folder" "$dest:~/$folder_name/"; then
            echo "    ✓ Successfully synced $folder to $dest"
        else
            echo "    ✗ Failed to sync $folder to $dest"
        fi
    done
    
    echo ""
done

echo "Sync complete!"
echo "================================"

# Optional: Verify sync by checking file counts
echo "Verification (file counts):"
for dest in "${DESTINATIONS[@]}"; do
    echo "Files on $dest:"
    for folder in "${FOLDERS[@]}"; do
        folder_name=$(basename "$folder")
        ssh "$dest" "find ~/$folder_name -type f 2>/dev/null | wc -l" 2>/dev/null || echo "  Could not check $folder_name on $dest"
    done
    echo ""
done