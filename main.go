package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"os/signal"
	"strings"
	"syscall"

	gosxnotifier "github.com/deckarep/gosx-notifier"
	"github.com/nxadm/tail"
)

var (
	version     = "dev"
	buildTime   = "unknown"
	bundleIdent = "com.example.lognotifier"
)

func init() {
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage of %s:\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "Version: %s (built %s, bundleIdent %s)\n", version, buildTime, bundleIdent)
		fmt.Fprintln(os.Stderr)
		flag.PrintDefaults()
	}
}

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

	// Setup signal handling for graceful shutdown
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	// Split keywords, removing empty ones
	rawKeywords := strings.Split(*searchStrings, ",")
	keywords := make([]string, 0, len(rawKeywords))
	for _, kw := range rawKeywords {
		kw = strings.TrimSpace(kw)
		if kw != "" {
			keywords = append(keywords, kw)
		}
	}
	if len(keywords) == 0 {
		fmt.Fprintln(os.Stderr, "Error: No valid keywords specified in -search.")
		os.Exit(1)
	}

	tailCfg := tail.Config{
		Follow:    true,
		ReOpen:    true, // Will reopen the file if rotated or recreated
		MustExist: true,
		Poll:      false,
		Location:  &tail.SeekInfo{Offset: 0, Whence: io.SeekEnd},
	}

	t, err := tail.TailFile(*logPath, tailCfg)
	if err != nil {
		log.Fatalf("Failed to tail file: %v", err)
	}
	defer t.Cleanup()

	// Channel to signal the main loop to exit
	done := make(chan struct{})

	go func() {
		for {
			select {
			case <-ctx.Done():
				log.Printf("Received interrupt signal, shutting down...")
				t.Stop()
				close(done)
				return
			case line, ok := <-t.Lines:
				if !ok {
					log.Printf("Log tailer stopped (file may have been rotated or deleted). Attempting to reopen in 2 seconds...")
					// Try to reopen after a short wait
					// You could add a backoff or max retries here if you want
					t.Stop()
					t.Cleanup()
					// Wait and try to reopen
					select {
					case <-ctx.Done():
						close(done)
						return
					case <-sleepCtx(ctx, 2):
					}
					t, err = tail.TailFile(*logPath, tailCfg)
					if err != nil {
						log.Printf("Failed to re-open log file: %v", err)
						close(done)
						return
					}
					continue
				}
				if line.Err != nil {
					log.Printf("Error reading line: %v", line.Err)
					continue
				}
				text := strings.TrimSpace(line.Text)
				if text == "" {
					continue // skip empty lines
				}
				for _, keyword := range keywords {
					if idx := strings.Index(strings.ToLower(text), strings.ToLower(keyword)); idx != -1 {
						notifyText := text[idx:]
						note := gosxnotifier.NewNotification(notifyText)
						note.Title = *notificationString
						note.Sender = bundleIdent
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
	}()

	// Wait for done signal
	<-done
	log.Println("Exiting lognotifier.")
}

// sleepCtx returns a channel that is closed after `sec` seconds or when ctx is done.
func sleepCtx(ctx context.Context, sec int) <-chan struct{} {
	ch := make(chan struct{})
	go func() {
		select {
		case <-ctx.Done():
		case <-timeAfterSeconds(sec):
		}
		close(ch)
	}()
	return ch
}

// timeAfterSeconds is a helper for sleepCtx to avoid importing time in main scope.
func timeAfterSeconds(sec int) <-chan struct{} {
	ch := make(chan struct{})
	go func() {
		// avoid importing time at top
		var sleep = func(s int) {
			for i := 0; i < s; i++ {
				// Sleep 1 second at a time so we can exit promptly on signal
				syscall.Sleep(1)
			}
		}
		sleep(sec)
		close(ch)
	}()
	return ch
}

