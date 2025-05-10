# LogNotifier

A very simple app that tails a logfile and sends a macOS notification when the specified word(s) is detected. Please be aware that I worked on this code just as an exercise on working with LLMs: just giving prompts and not wrinting or bugfixing the code manually. A fun and sometimes frustrating exercise, TBH ;)

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

First of all, the code is macOS specific. Tested on 15.4.1, that basically means "It (somehow) works for me"
Of course, you need golang installed, but this should be obvious as here you can find only source code.


### Installation


Are you sure?
```
$ https://github.com/cova-fe/lognotifier.git
$ cd lognotifier
```
Customize the Makefile to your liking; there should be enough comment to get you started.
```
$ make build
```
You may want to check other make targets, to create plist file and even a bundle. Not yet tested, likely they won't work :)

## Usage
Run it.
```
$ ./lognotifier 
```

## Deployment

If you want to use system-level installation:
```
sudo launchctl load /Library/LaunchDaemons/com.example.lognotifier.plist
sudo launchctl unload /Library/LaunchDaemons/com.example.lognotifier.plist
```

User-level:
```
launchctl unload ~/Library/LaunchAgents/com.example.lognotifier.plist
launchctl load ~/Library/LaunchAgents/com.example.lognotifier.plist
```
