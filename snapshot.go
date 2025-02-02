package main

import (
	"flag"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"syscall"
	"time"
)

func main() {
	// Define command-line flags.
	var (
		targetPath  string
		hourlyRet   int
		dailyRet    int
		monthlyRet  int
	)

	// Retention values: if 0 then that snapshot type is disabled.
	flag.StringVar(&targetPath, "path", "", "Target path where .snap directory is created")
	flag.IntVar(&hourlyRet, "hourly", 0, "Number of hourly snapshots to retain (0 disables hourly snapshots)")
	flag.IntVar(&dailyRet, "daily", 0, "Number of daily snapshots to retain (0 disables daily snapshots)")
	flag.IntVar(&monthlyRet, "monthly", 0, "Number of monthly snapshots to retain (0 disables monthly snapshots)")
	flag.Parse()

	if targetPath == "" {
		log.Fatal("You must specify a target path using the -path flag")
	}

	// Create the .snap subdirectory inside the target path.
	snapDir := filepath.Join(targetPath, ".snap")
	if err := os.MkdirAll(snapDir, 0755); err != nil {
		log.Fatalf("failed to create .snap directory: %v", err)
	}

	now := time.Now()

	// If a retention value is specified (> 0) for a given type, then create its snapshot and rotate.
	if hourlyRet > 0 {
		hourlyName := "hourly-" + now.Format("2006010215")
		createSnapshotIfNotExists(snapDir, hourlyName)
		rotateSnapshots(snapDir, "hourly-", hourlyRet)
	}

	if dailyRet > 0 {
		dailyName := "daily-" + now.Format("20060102")
		createSnapshotIfNotExists(snapDir, dailyName)
		rotateSnapshots(snapDir, "daily-", dailyRet)
	}

	if monthlyRet > 0 {
		monthlyName := "monthly-" + now.Format("200601")
		createSnapshotIfNotExists(snapDir, monthlyName)
		rotateSnapshots(snapDir, "monthly-", monthlyRet)
	}
}

// createSnapshotIfNotExists creates a snapshot directory (inside snapDir) with the given name
// if it does not already exist.
func createSnapshotIfNotExists(snapDir, snapName string) {
	snapPath := filepath.Join(snapDir, snapName)
	if _, err := os.Stat(snapPath); os.IsNotExist(err) {
		if err := os.Mkdir(snapPath, 0755); err != nil {
			log.Printf("failed to create snapshot %s: %v", snapPath, err)
		} else {
			log.Printf("Created snapshot: %s", snapPath)
		}
	} else if err != nil {
		log.Printf("failed to stat snapshot %s: %v", snapPath, err)
	} else {
		log.Printf("Snapshot %s already exists", snapPath)
	}
}

// rotateSnapshots removes old snapshot directories for a given type (with the given prefix)
// if the number of snapshots exceeds the retention limit. The removal is done using syscall.Rmdir.
func rotateSnapshots(snapDir, prefix string, retention int) {
	entries, err := os.ReadDir(snapDir)
	if err != nil {
		log.Printf("failed to read directory %s: %v", snapDir, err)
		return
	}

	// Collect snapshot directories with the given prefix.
	var snaps []string
	for _, entry := range entries {
		if entry.IsDir() && strings.HasPrefix(entry.Name(), prefix) {
			snaps = append(snaps, entry.Name())
		}
	}

	// Sort snapshot names in lexicographical order.
	// The timestamp formats in the names guarantee that lexicographical order equals chronological order.
	sort.Strings(snaps)

	// If there are more snapshots than the retention limit, remove the oldest ones.
	if len(snaps) > retention {
		numToRemove := len(snaps) - retention
		for i := 0; i < numToRemove; i++ {
			snapToRemove := filepath.Join(snapDir, snaps[i])
			// Use syscall.Rmdir to remove the snapshot directory.
			if err := syscall.Rmdir(snapToRemove); err != nil {
				log.Printf("failed to remove snapshot %s: %v", snapToRemove, err)
			} else {
				log.Printf("Removed old snapshot: %s", snapToRemove)
			}
		}
	}
}
