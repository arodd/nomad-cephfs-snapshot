
# Cephfs Snapshot Manager

A simple Go application that creates and rotates snapshot directories (hourly, daily, monthly) in a specified path. Snapshots are stored in a hidden `.snap` directory which works with cephfs filesysems.

## Usage

1. **Build the Application:**

   ```bash
   go build -o snapshot
   ```

2. **Run the Application:**

   ```bash
   ./snapshot -path=/your/path -hourly=24 -daily=7 -monthly=12
   ```

   - This command creates snapshots in `/your/path/.snap`:
     - **Hourly snapshots:** Retains the latest 24 snapshots.
     - **Daily snapshots:** Retains the latest 7 snapshots.
     - **Monthly snapshots:** Retains the latest 12 snapshots.

3. **Disable a Snapshot Type:**

   Set the retention value to `0` or omit the flag for any snapshot type you do not want to manage. For example, to manage only daily snapshots:

   ```bash
   ./snapshot -path=/your/path -daily=7
   ```

## Flags

- `-path`  
  The base directory where the `.snap` subdirectory is created.

- `-hourly`  
  Number of hourly snapshots to retain (set to `0` to disable).

- `-daily`  
  Number of daily snapshots to retain (set to `0` to disable).

- `-monthly`  
  Number of monthly snapshots to retain (set to `0` to disable).

