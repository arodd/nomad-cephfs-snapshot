#!/bin/bash
#
# CephFS Snapshot Manager Bash Script
#
# This script creates and rotates snapshot directories in a .snap subdirectory
# within a specified target path. It supports hourly, daily, and monthly snapshots.
#
# Usage:
#   ./snapshot.sh -path /your/path -hourly 24 -daily 7 -monthly 12
#
# To disable a snapshot type, set its retention value to 0. For example, to manage
# only daily snapshots:
#   ./snapshot.sh -path /your/path -hourly 0 -daily 7 -monthly 0
#

# Function to display usage information.
usage() {
  echo "Usage: $0 -path <target_path> [-hourly <num>] [-daily <num>] [-monthly <num>]"
  echo "  -path      : The base directory where the .snap subdirectory is created."
  echo "  -hourly    : Number of hourly snapshots to retain (0 disables hourly snapshots)."
  echo "  -daily     : Number of daily snapshots to retain (0 disables daily snapshots)."
  echo "  -monthly   : Number of monthly snapshots to retain (0 disables monthly snapshots)."
  exit 1
}

# Parse command-line arguments.
TARGET_PATH=""
HOURLY_RET=0
DAILY_RET=0
MONTHLY_RET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -path)
      TARGET_PATH="$2"
      shift 2
      ;;
    -hourly)
      HOURLY_RET="$2"
      shift 2
      ;;
    -daily)
      DAILY_RET="$2"
      shift 2
      ;;
    -monthly)
      MONTHLY_RET="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

if [[ -z "$TARGET_PATH" ]]; then
  echo "Error: -path is required."
  usage
fi

# Create the .snap directory under the target path.
SNAP_DIR="${TARGET_PATH}/.snap"
mkdir -p "$SNAP_DIR"

# Function to create a snapshot directory if it doesn't exist.
create_snapshot() {
  local snap_name="$1"
  local snap_path="${SNAP_DIR}/${snap_name}"
  if [[ ! -d "$snap_path" ]]; then
    if mkdir "$snap_path"; then
      echo "Created snapshot: $snap_path"
    else
      echo "Failed to create snapshot: $snap_path"
    fi
  else
    echo "Snapshot already exists: $snap_path"
  fi
}

# Function to rotate snapshots.
# It lists all directories in SNAP_DIR that begin with the given prefix,
# sorts them lexicographically, and removes the oldest directories if their
# count exceeds the specified retention limit.
rotate_snapshots() {
  local prefix="$1"
  local retention="$2"
  # List directories matching the prefix and sort them.
  mapfile -t snaps < <(ls -1 "$SNAP_DIR" | grep "^${prefix}" | sort)
  local count=${#snaps[@]}
  if (( count > retention )); then
    local num_to_remove=$(( count - retention ))
    for (( i = 0; i < num_to_remove; i++ )); do
      local snap_to_remove="${SNAP_DIR}/${snaps[i]}"
      if rmdir "$snap_to_remove" 2>/dev/null; then
        echo "Removed old snapshot: $snap_to_remove"
      else
        echo "Failed to remove snapshot (directory not empty?): $snap_to_remove"
      fi
    done
  fi
}

# Get the current dates for naming snapshots.
CURRENT_DATE_HOURLY=$(date +%Y%m%d%H)
CURRENT_DATE_DAILY=$(date +%Y%m%d)
CURRENT_DATE_MONTHLY=$(date +%Y%m)

# Process hourly snapshots if enabled.
if (( HOURLY_RET > 0 )); then
  HOURLY_SNAPSHOT="hourly-${CURRENT_DATE_HOURLY}"
  create_snapshot "$HOURLY_SNAPSHOT"
  rotate_snapshots "hourly-" "$HOURLY_RET"
fi

# Process daily snapshots if enabled.
if (( DAILY_RET > 0 )); then
  DAILY_SNAPSHOT="daily-${CURRENT_DATE_DAILY}"
  create_snapshot "$DAILY_SNAPSHOT"
  rotate_snapshots "daily-" "$DAILY_RET"
fi

# Process monthly snapshots if enabled.
if (( MONTHLY_RET > 0 )); then
  MONTHLY_SNAPSHOT="monthly-${CURRENT_DATE_MONTHLY}"
  create_snapshot "$MONTHLY_SNAPSHOT"
  rotate_snapshots "monthly-" "$MONTHLY_RET"
fi

