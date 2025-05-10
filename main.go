package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strings"

	"io"

	gosxnotifier "github.com/deckarep/gosx-notifier"
	"github.com/nxadm/tail"
)

var (
	version   = "dev"
	buildTime = "unknown"
)

func main() {
	searchStrings := flag.String("search", "", "Comma-separated list of strings to search for in the log")
	logPath := flag.String("log", "", "Path to the log file")
	notificationString := flag.String("ident", "LogNotifier", "Identifier for the notification")

	flag.Parse()

	if *logPath == "" {
		fmt.Fprintln(os.Stderr, "Error: The -log parameter is required.")
		flag.Usage()
		os.Exit(1)
	}

	if *searchStrings == "" {
		fmt.Fprintln(os.Stderr, "Error: The -search parameter is required.")
		flag.Usage()
		os.Exit(1)
	}

	fmt.Printf("Log Notifier v%s (built %s)\n", version, buildTime)
	fmt.Printf("Watching file: %s\n", *logPath)
	fmt.Printf("Searching for: %q\n", *searchStrings)

	t, err := tail.TailFile(*logPath, tail.Config{
		Follow:    true,
		ReOpen:    true,
		MustExist: true,
		Poll:      false,
		Location:  &tail.SeekInfo{Offset: 0, Whence: io.SeekEnd},
	})
	if err != nil {
		log.Fatalf("Failed to tail file: %v", err)
	}

	keywords := strings.Split(*searchStrings, ",")

	for line := range t.Lines {
		if line.Err != nil {
			log.Printf("Error reading line: %v", line.Err)
			continue
		}
		for _, keyword := range keywords {
			keyword = strings.TrimSpace(keyword)
			if idx := strings.Index(line.Text, keyword); idx != -1 {
				notifyText := line.Text[idx:]
				note := gosxnotifier.NewNotification(notifyText)
				note.Title = *notificationString
				note.Group = strings.ToLower(*notificationString)
				if err := note.Push(); err != nil {
					log.Printf("Notification error: %v", err)
				} else {
					log.Printf("🔔 Notified: %s", notifyText)
				}
				break // avoid multiple notifications for one line
			}
		}
	}
}
