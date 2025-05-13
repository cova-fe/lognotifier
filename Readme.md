# LogNotifier

A very simple app that tails a logfile and sends a macOS notification when the specified word(s) is detected. Please be aware that I worked on this code just as an exercise on working with LLMs: just giving prompts and not wrinting or bugfixing the code manually. A fun and sometimes frustrating exercise, TBH ;)

## Current status
It somehow works. On my machine. On a good day. Still tweaking it, so no unit testing and other similar stuff. No expectations of any kind.

## Prerequisites

First of all, the code is macOS specific. Tested on 15.5. Of course, you need golang installed, but this should be obvious as here you can find only source code.


## Build

Please be aware that VERSION file holds the version in _major.minor.patch_ format
```
$ https://github.com/cova-fe/lognotifier.git
$ cd lognotifier
$ make build
```
Variables that can be used to modify Makefile behavior:  
`APP_NAME`: used for binary, bundle, etc. _Default: lognotifier_  
`ORG_NAME`: The org used to create the bundle and plist files. _Default: com.example_  
`BIN_DIR`: Where to put the binary file. _Default: $pwd_  

example:
```
make APP_NAME=whatever build
```

### Available make targets
* `build` creates the binary
* `install-bin` install binary file into BIN_DIR
* `bump-major` bumps major version in VERSION file
* `bump-minor` bumps minor version in VERSION file
* `bump-patch` bumps patch version in VERSION file
* `show-version` prints current version in VERSION file
* `git-tag` tags current git commit with version in VERSION file
* `generate-launchagent-plist` creates plist made for launchd
* `install-plist` installs launchd plist
* `generate-bundle-plist` creates plist for bundle
* `macos-bundle` creates macos bundle
* `macos-install` installs macos bundle
* `clean` you guessed it.

# Usage
```
$ ./lognotifier
```

# Installation

Check out *-install targets above.

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

You may want to modify the content of `.plist` files to suit your needs
