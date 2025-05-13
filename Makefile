APP_NAME := lognotifier
VERSION := $(shell cat VERSION)
BUILD_TIME := $(shell date -u +"%Y-%m-%dTH%H:%M:%SZ")
VERSION_FILE := VERSION

# Variable for the single source PNG icon file
# Recommended minimum size is 1024x1024 pixels for best results across all resolutions.
ICON_PNG := assets/source_icon.png

# Variable for the macOS bundle identifier (e.g., com.yourcompany.appname)
BUNDLE_ID := com.example.$(APP_NAME)

# Variables for the bundle structure
BUNDLE_NAME := $(APP_NAME).app
CONTENTS_DIR := $(BUNDLE_NAME)/Contents
MACOS_DIR := $(CONTENTS_DIR)/MacOS
RESOURCES_DIR := $(CONTENTS_DIR)/Resources
BUNDLE_EXECUTABLE := $(MACOS_DIR)/$(APP_NAME)
BUNDLE_ICON := $(RESOURCES_DIR)/AppIcon.icns
BUNDLE_PLIST_DEST := $(CONTENTS_DIR)/Info.plist

# Variable for the standalone Info.plist file generated for the bundle
BUNDLE_PLIST_SRC := $(APP_NAME).Bundle.plist

# Variable for the standalone LaunchAgent plist file
LAUNCHAGENT_PLIST_SRC := $(BUNDLE_ID).LaunchAgent.plist

# --- Installation Variables ---

# Base directory for installation. Defaults to user's home directory.
# Override with 'INSTALL_ROOT=/' for system-wide installation (requires sudo).
INSTALL_ROOT := $(HOME)

# Default installation directory for application bundles
INSTALL_DIR := $(INSTALL_ROOT)/Applications

# Default installation directory for user or system LaunchAgents
LAUNCHAGENTS_DIR := $(INSTALL_ROOT)/Library/LaunchAgents

# Path for the installed LaunchAgent plist file
INSTALLED_LAUNCHAGENT_PLIST := $(LAUNCHAGENTS_DIR)/$(BUNDLE_ID).plist

# Path to the executable that the LaunchAgent plist will reference in ProgramArguments.
# Defaults to the absolute path of the executable built in the current directory.
# IMPORTANT: If you install the executable elsewhere (e.g., /usr/local/bin), you MUST
# override this variable when generating/installing the launchagent plist.
LAUNCHD_EXEC_PATH := $(shell realpath $(APP_NAME))

# --- End Installation Variables ---


# Variable for the temporary base directory for icon creation
TEMP_BASE_DIR := $(shell mktemp -p /tmp -d -t $(APP_NAME)_icon_XXXX)
# Variable for the actual iconset directory (must end with .iconset)
ICONSET_DIR := $(TEMP_BASE_DIR)/AppIcon.iconset
@echo "Temporary iconset directory: $(ICONSET_DIR)"

define read-version
	$(shell cat $(VERSION_FILE) | awk '{$$1=$$1};1')
endef

define heredoc_bundle_plist
cat <<EOF > "$(BUNDLE_PLIST_SRC)"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>$(APP_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(BUNDLE_ID)</string>
	<key>CFBundleVersion</key>
	<string>$(VERSION)</string>
	<key>CFBundleShortVersionString</key>
	<string>$(VERSION)</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
EOF
endef
export heredoc_bundle_plist

define heredoc_launchagent_plist
cat <<EOF > "$(LAUNCHAGENT_PLIST_SRC)"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$(BUNDLE_ID)</string>
	<key>ProgramArguments</key>
	<array>
		<string>$(LAUNCHD_EXEC_PATH)</string>
		# Add any command line arguments here as <string> items
		# <string>--config</string>
		# <string>/path/to/config.yaml</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<false/>

	# Optional keys for logging stdout and stderr
	# <key>StandardOutPath</key>
	# <string>$(HOME)/Library/Logs/$(APP_NAME)_stdout.log</string> # Use $(HOME) for user path
	# <key>StandardErrorPath</key>
	# <string>$(HOME)/Library/Logs/$(APP_NAME)_stderr.log</string> # Use $(HOME) for user path

	# Optional: Set working directory
	# <key>WorkingDirectory</key>
	# <string>/path/where/your/executable/should/run</string> # e.g., $(shell dirname $(LAUNCHD_EXEC_PATH))

</dict>
</plist>
EOF

endef
export heredoc_launchagent_plist


# Added specific plist generation targets and updated install targets
.PHONY: all build clean run git-tag bump-patch bump-minor bump-major macos-bundle generate-bundle-plist generate-launchagent-plist macos-install install-plist show-version

all: build

# Build the app using the version and build time
build:
	@echo "Building $(APP_NAME) version $(VERSION) with build time $(BUILD_TIME)..."; \
	go build -ldflags "-X main.version=$(VERSION) -X main.buildTime=$(BUILD_TIME)" -o $(APP_NAME) main.go;

# Clean build artifacts, including both types of standalone plists and the installed launchagent plist
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(APP_NAME)
	rm -rf "$(BUNDLE_NAME)"
	rm -f "$(BUNDLE_PLIST_SRC)"
	rm -f "$(LAUNCHAGENT_PLIST_SRC)"
	rm -rf "$(INSTALL_DIR)/$(BUNDLE_NAME)"
	rm -f "$(INSTALLED_LAUNCHAGENT_PLIST)"
	rm -rf "$(TEMP_BASE_DIR)"

# Run the app
run: build
	./$(APP_NAME)

show-version:
	@echo "Current version: $(call read-version)"

bump-major:
	@echo "Bumping major version..."
	@VERSION="$(call read-version);" \
	MAJOR=$$(echo $$VERSION | cut -d. -f1); \
	NEW_MAJOR=$$((MAJOR + 1)); \
	NEW_VERSION=$${NEW_MAJOR}.0.0; \
	echo "New version: $$NEW_VERSION"; \
	echo "$$NEW_VERSION" > $(VERSION_FILE)

bump-minor:
	@echo "Bumping minor version..."
	@VERSION="$(call read-version);" \
	MAJOR=$$(echo $$VERSION | cut -d. -f1); \
	MINOR=$$(echo $$VERSION | cut -d. -f2); \
	NEW_MINOR=$$((MINOR + 1)); \
	NEW_VERSION=$${MAJOR}.$${NEW_MINOR}.0; \
	echo "New version: $$NEW_VERSION"; \
	echo "$$NEW_VERSION" > $(VERSION_FILE)

bump-patch:
	@echo "Bumping patch version..."
	@VERSION="$(call read-version);" \
	MAJOR=$$(echo $$VERSION | cut -d. -f1); \
	MINOR=$$(echo $$VERSION | cut -d. -f2); \
	PATCH=$$(echo $$VERSION | cut -d. -f3); \
	NEW_PATCH=$$((PATCH + 1)); \
	NEW_VERSION=$${MAJOR}.$${MINOR}.$${NEW_PATCH}; \
	echo "New version: $$NEW_VERSION"; \
	echo "$$NEW_VERSION" > $(VERSION_FILE)

git-tag:
	@echo "Creating Git tag..."
	@[ -f $(VERSION_FILE) ] || { echo "Error: $(VERSION_FILE) not found!"; exit 1; }; \
	# Optional: Also check format if strict format is required for tags
	# grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$$' $(VERSION_FILE) || { echo "Error: $(VERSION_FILE) content is not in major.minor.patch format!"; exit 1; }; \
	# --- End Error Handling ---
	NEW_VERSION=$$(cat $(VERSION_FILE)); \
	echo "Tagging version $${NEW_VERSION}"; \
	git tag -a "v$${NEW_VERSION}" -m "Release version $${NEW_VERSION}"; \
	git push --tags

# Generate the standalone Info.plist file for the macOS application bundle
generate-bundle-plist:
	@echo "Generating bundle Info.plist: $(BUNDLE_PLIST_SRC)..."
	@sh -c '\
	[ -n "$(APP_NAME)" ] || { echo "Error: APP_NAME variable is not set!"; exit 1; }; \
	[ -n "$(BUNDLE_ID)" ] || { echo "Error: BUNDLE_ID variable is not set!"; exit 1; }; \
	[ -f $(VERSION_FILE) ] || { echo "Error: $(VERSION_FILE) not found!"; exit 1; }; \
	grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$$' $(VERSION_FILE) || { echo "Error: $(VERSION_FILE) content is not in major.minor.patch format!"; exit 1; }'\
	; \
	eval "$$heredoc_bundle_plist"
	echo "$(BUNDLE_PLIST_SRC) generated."

# Generate the standalone plist file for a LaunchAgent
generate-launchagent-plist: build
	@echo "Generating LaunchAgent plist: $(LAUNCHAGENT_PLIST_SRC)..."
	@sh -c '\
	[ -n "$(APP_NAME)" ] || { echo "Error: APP_NAME variable is not set!"; exit 1; }; \
	[ -n "$(BUNDLE_ID)" ] || { echo "Error: BUNDLE_ID variable is not set!"; exit 1; }; \
	[ -n "$(LAUNCHD_EXEC_PATH)" ] || { echo "Error: LAUNCHD_EXEC_PATH variable is not set!"; exit 1; }; \
	[ -f $(VERSION_FILE) ] || { echo "Error: $(VERSION_FILE) not found!"; exit 1; }; \
	grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$$' $(VERSION_FILE) || { echo "Error: $(VERSION_FILE) content is not in major.minor.patch format!"; exit 1; }; \
	[ -x "$(LAUNCHD_EXEC_PATH)" ] || { echo "Warning: LAUNCHD_EXEC_PATH ($(LAUNCHD_EXEC_PATH)) does not exist or is not executable at build time. Ensure the path is correct for the runtime environment."; }'\
	; \
	eval "$$heredoc_launchagent_plist"
	echo "$(LAUNCHAGENT_PLIST_SRC) generated."

# Create a macOS application bundle (.app)
macos-bundle: build generate-bundle-plist
	@echo "Creating macOS bundle $(BUNDLE_NAME)..."
	@sh -c '\
	[ -n "$(ICON_PNG)" ] || { echo "Error: ICON_PNG variable is not set!"; exit 1; }; \
	[ -f "$(ICON_PNG)" ] || { echo "Error: ICON_PNG file not found: $(ICON_PNG)!"; exit 1; }; \
	[ -f "$(BUNDLE_PLIST_SRC)" ] || { echo "Error: Bundle plist not found: $(BUNDLE_PLIST_SRC)! Run '\''make generate-bundle-plist'\'' first."; exit 1; }'\
	; \
	rm -rf "$(BUNDLE_NAME)"; \
	mkdir -p "$(MACOS_DIR)" "$(RESOURCES_DIR)"; \
	cp "$(APP_NAME)" "$(BUNDLE_EXECUTABLE)"; \
	cp "$(BUNDLE_PLIST_SRC)" "$(BUNDLE_PLIST_DEST)"; \
	echo "Generating iconset from $(ICON_PNG) in temporary directory $(ICONSET_DIR)..."; \
	mkdir -p "$(ICONSET_DIR)"; \
	sips -z 16 16 "$(ICON_PNG)" --out "$(ICONSET_DIR)/icon_16x16.png" || { echo "Error generating icon_16x16.png!"; rm -rf "$(TEMP_BASE_DIR)"; exit 1; }; \
	sips -z 32 32 "$(ICON_PNG)" --out "$(ICONSET_DIR)/icon_16x16@2x.png" || { echo "Error generating icon_16x16@2x.png!"; rm -rf "$(TEMP_BASE_DIR)"; exit 1; }; \
	sips -z 32 32 "$(ICON_PNG)" --out "$(ICONSET_DIR)/icon_32x32.png" || { echo "Error generating icon_32x32.png!"; rm -rf "$(TEMP_BASE_DIR)"; exit 1; }; \
	sips -z 64 64 "$(ICON_PNG)" --out "$(ICONSET_DIR)/icon_32x32@2x.png" || { echo "Error generating icon_32x32@2x.png!"; rm -rf "$(TEMP_BASE_DIR)"; exit 1; }; \
	sips -z 128 128 "$(ICON_PNG)" --out "$(ICONSET_DIR)/icon_128x128.png" || { echo "Error generating icon_128x128.png!"; rm -rf "$(TEMP_BASE_DIR)"; exit 1; }; \
	sips -z 256 256 "$(ICON_PNG)" --out "$(ICONSET_DIR)/icon_128x128@2x.png" || { echo "Error generating icon_128x128@2x.png!"; rm -rf "$(TEMP_BASE_DIR)"; exit 1; }; \
	sips -z 256 256 "$(ICON_PNG)" --out "$(ICONSET_DIR)/icon_256x256.png" || { echo "Error generating icon_256x256.png!"; rm -rf "$(TEMP_BASE_DIR)"; exit 1; }; \
	sips -z 512 512 "$(ICON_PNG)" --out "$(ICONSET_DIR)/icon_256x256@2x.png" || { echo "Error generating icon_256x256@2x.png!"; rm -rf "$(TEMP_BASE_DIR)"; exit 1; }; \
	sips -z 512 512 "$(ICON_PNG)" --out "$(ICONSET_DIR)/icon_512x512.png" || { echo "Error generating icon_512x512.png!"; rm -rf "$(TEMP_BASE_DIR)"; exit 1; }; \
	sips -z 1024 1024 "$(ICON_PNG)" --out "$(ICONSET_DIR)/icon_512x512@2x.png" || { echo "Error generating icon_512x512@2x.png!"; rm -rf "$(TEMP_BASE_DIR)"; exit 1; }; \
	iconutil -c icns "$(ICONSET_DIR)" -o "$(BUNDLE_ICON)" || { echo "Error creating icon with iconutil!"; rm -rf "$(TEMP_BASE_DIR)"; exit 1; }; \
	rm -rf "$(TEMP_BASE_DIR)"

	@echo "Bundle created: $(BUNDLE_NAME)"

# Install the macOS application bundle to the Applications folder based on INSTALL_ROOT
macos-install: macos-bundle
	@echo "Installing $(BUNDLE_NAME) to $(INSTALL_DIR)..."
	@# --- Error Handling: Check if the bundle exists ---
	@[ -d "$(BUNDLE_NAME)" ] || { echo "Error: Bundle not found: $(BUNDLE_NAME)! Run 'make macos-bundle' first."; exit 1; }
	@mkdir -p "$(INSTALL_DIR)" || { echo "Error creating install directory: $(INSTALL_DIR)!"; exit 1; }
	@cp -R "$(BUNDLE_NAME)" "$(INSTALL_DIR)/" || { echo "Error copying bundle to $(INSTALL_DIR)!"; exit 1; }
	@echo "Installation of bundle complete."
	@# Note: For system-wide install (INSTALL_ROOT=/), you typically need to run this with sudo.

# Install the standalone LaunchAgent plist file to the LaunchAgents folder based on INSTALL_ROOT
install-plist: generate-launchagent-plist
	@echo "Installing LaunchAgent plist $(LAUNCHAGENT_PLIST_SRC) to $(INSTALLED_LAUNCHAGENT_PLIST)..."
	@[ -f "$(LAUNCHAGENT_PLIST_SRC)" ] || { echo "Error: Standalone LaunchAgent plist not found: $(LAUNCHAGENT_PLIST_SRC)! Run 'make generate-launchagent-plist' first."; exit 1; }
	@mkdir -p "$(LAUNCHAGENTS_DIR)" || { echo "Error creating LaunchAgents directory: $(LAUNCHAGENTS_DIR)!"; exit 1; }
	@cp "$(LAUNCHAGENT_PLIST_SRC)" "$(INSTALLED_LAUNCHAGENT_PLIST)" || { echo "Error copying plist to $(LAUNCHAGENTS_DIR)!"; exit 1; }
	@echo "Installation of LaunchAgent plist complete."
	@echo "Note: You may need to load the agent using 'launchctl load $(INSTALLED_LAUNCHAGENT_PLIST)'"
	@# Note: For system-wide install (INSTALL_ROOT=/), this targets /Library/LaunchAgents.
	@# You typically need to run this with sudo for system-wide installation.
