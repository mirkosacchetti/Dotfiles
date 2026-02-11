#!/bin/bash
# backup_external.sh - Script for incremental backup to encrypted external disk using duplicity

# Configuration
DISK_NAME="red"  
BACKUP_DIR="backup"
LOGFILE="/home/m/Desktop/duplicity_backup.log"
SOURCE="/home/m"

# Function for logging messages
log() {
  local message="[$(date)] $1"
  echo "$message" >> "$LOGFILE"
  echo "$message"
}

# Get disk path
DISK=$(lsblk -o NAME,LABEL,PATH | grep "$DISK_NAME" | awk '{print $3}' | head -n1)
if [ -z "$DISK" ]; then
  log "Disk with label $DISK_NAME not found. Exiting."
  exit 1
fi

# Set mount point
MOUNT_POINT=$(findmnt -n -o TARGET -S "$DISK" 2>/dev/null)
if [ -z "$MOUNT_POINT" ] || [ ! -d "$MOUNT_POINT" ]; then
  MOUNT_POINT="/mnt/backup"
fi

# Set mapper name and path
MAPPER_NAME="$DISK_NAME"
MAPPER="/dev/mapper/$MAPPER_NAME"
log "Checking for disk $DISK..."
if [ ! -b "$DISK" ]; then
  log "Disk $DISK not connected. Exiting."
  exit 1
fi
log "Disk $DISK found."

log "Checking mount point $MOUNT_POINT..."
if [ ! -d "$MOUNT_POINT" ]; then
  log "Creating mount point $MOUNT_POINT..."
  sudo mkdir -p "$MOUNT_POINT"
fi

log "Checking if disk is already mapped..."
ACTUAL_MAPPER=""
for m in /dev/mapper/*; do
  if sudo cryptsetup status $(basename $m) 2>/dev/null | grep -q "$DISK"; then
    ACTUAL_MAPPER=$m
    ACTUAL_MAPPER_NAME=$(basename $m)
    log "Disk $DISK is already mapped as $ACTUAL_MAPPER"
    break
  fi
done

if [ -z "$ACTUAL_MAPPER" ]; then
  log "Unlocking encrypted disk $DISK with mapper $MAPPER_NAME..."
  if sudo cryptsetup open "$DISK" "$MAPPER_NAME"; then
    ACTUAL_MAPPER=$MAPPER
    ACTUAL_MAPPER_NAME=$MAPPER_NAME
  else
    log "Could not unlock disk. Perhaps it's already in use."
  fi
else
  MAPPER=$ACTUAL_MAPPER
  MAPPER_NAME=$ACTUAL_MAPPER_NAME
fi

EXISTING_MOUNT=$(findmnt -n -o TARGET $MAPPER 2>/dev/null)
if [ -n "$EXISTING_MOUNT" ]; then
  log "Device $MAPPER is already mounted at $EXISTING_MOUNT"
  MOUNT_POINT=$EXISTING_MOUNT
  DEST="file://${MOUNT_POINT}/backup"
  log "Using existing mount point: $MOUNT_POINT"
else
  log "Mounting device $MAPPER on $MOUNT_POINT..."
  sudo mount "$MAPPER" "$MOUNT_POINT" || log "Could not mount device. Perhaps there's an issue with the filesystem."
fi

if mountpoint -q "$MOUNT_POINT"; then
  log "Device mounted successfully on $MOUNT_POINT"
  df -h "$MOUNT_POINT" | log
  log "Launching duplicity..."
  
  NEW_DEST="file://${MOUNT_POINT}/${BACKUP_DIR}"
  log "Using backup destination: $NEW_DEST"
  
  if [ -d "${MOUNT_POINT}/${BACKUP_DIR}" ] && [ -f "${MOUNT_POINT}/${BACKUP_DIR}/duplicity-full-signatures."*".sigtar.gpg" ]; then
    log "Detected existing encrypted backup. Using a clean backup directory to avoid conflicts."
    BACKUP_DIR="backup"
    NEW_DEST="file://${MOUNT_POINT}/${BACKUP_DIR}"
    log "Using new backup destination: $NEW_DEST"
    mkdir -p "${MOUNT_POINT}/${BACKUP_DIR}"
  fi
  
  duplicity \
    --no-encryption \
    --full-if-older-than 2M \
    --force \
    --include "$HOME/Books/" \
    --include "$HOME/Code/" \
    --include "$HOME/Documents/" \
    --include "$HOME/Audio/" \
    --include "$HOME/Books/" \
    --include "$HOME/Pictures/" \
    --include "$HOME/Projects/" \
    --include "$HOME/Prompts/" \
    --include "$HOME/Hacks/" \
    --include "$HOME/Public/" \
    --include "$HOME/Video/" \
    --include "$HOME/Writings/" \
    --exclude "**" \
    --verbosity info "$HOME" "$NEW_DEST" | tee "$LOGFILE"
  
  log "Unmounting device from $MOUNT_POINT..."
  sudo umount "$MOUNT_POINT" || log "Could not unmount device. It may be in use."
else
  log "Device not mounted. Cannot proceed with backup."
fi

log "Checking if we should close the mapper..."
if [ "$MAPPER_NAME" = "$DISK_NAME" ] && [ -e "$MAPPER" ]; then
  log "Closing encrypted device $MAPPER_NAME..."
  sudo cryptsetup close "$MAPPER_NAME" || log "Could not close mapper. It may still be in use."
else
  log "Skipping mapper close as we're using an existing mapper: $MAPPER_NAME"
fi

log "Done."
