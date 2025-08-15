#!/bin/bash

# Setup script for local DBus system daemon development environment
# Checks dependencies, generates configuration, and prepares environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/dbus-system-local.template.conf"
CONFIG_FILE="$SCRIPT_DIR/dbus-system-local.conf"
SOCKET_DIR="/tmp/dbus-system-local"

echo "🔧 Setting up local DBus system daemon environment..."
echo ""

# Platform detection
OS_TYPE="$(uname -s)"
case "$OS_TYPE" in
    Linux*)
        PLATFORM="Linux"
        PACKAGE_MANAGERS=("apt-get" "yum" "dnf" "pacman" "zypper")
        ;;
    Darwin*)
        PLATFORM="macOS"
        PACKAGE_MANAGERS=("brew")
        ;;
    *)
        echo "❌ Unsupported platform: $OS_TYPE"
        exit 1
        ;;
esac

echo "🖥️  Platform detected: $PLATFORM"

# Check if dbus-daemon is installed
echo "🔍 Checking for dbus-daemon..."
if command -v dbus-daemon >/dev/null 2>&1; then
    DBUS_VERSION=$(dbus-daemon --version | head -n1)
    echo "✅ Found: $DBUS_VERSION"
else
    echo "❌ dbus-daemon not found!"
    echo ""
    echo "📦 Installation instructions:"
    
    case "$PLATFORM" in
        Linux)
            echo "   Ubuntu/Debian: sudo apt-get install dbus"
            echo "   CentOS/RHEL:   sudo yum install dbus"
            echo "   Fedora:        sudo dnf install dbus"
            echo "   Arch:          sudo pacman -S dbus"
            echo "   openSUSE:      sudo zypper install dbus-1"
            ;;
        macOS)
            echo "   Homebrew:      brew install dbus"
            echo "   MacPorts:      sudo port install dbus"
            ;;
    esac
    
    echo ""
    echo "⚠️  Please install dbus-daemon and run this setup again."
    exit 1
fi

# Get current user
CURRENT_USER="$(whoami)"
echo "👤 Current user: $CURRENT_USER"

# Check if template file exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "❌ Template file not found: $TEMPLATE_FILE"
    exit 1
fi

# Check if configuration file already exists
if [[ -f "$CONFIG_FILE" ]]; then
    echo "⚠️  Configuration file already exists: $CONFIG_FILE"
    read -p "   Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "🚫 Setup cancelled. Existing configuration preserved."
        exit 0
    fi
fi

# Generate configuration file from template
echo "📝 Generating configuration file from template..."
sed "s/{{USERNAME}}/$CURRENT_USER/g" "$TEMPLATE_FILE" > "$CONFIG_FILE"

echo "✅ Configuration file created: $CONFIG_FILE"

# Create socket directory
echo "📁 Creating socket directory..."
mkdir -p "$SOCKET_DIR"
echo "✅ Socket directory ready: $SOCKET_DIR"

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x "$SCRIPT_DIR"/*.sh
echo "✅ Scripts are now executable"

# Final check
echo ""
echo "🎉 Setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Start daemon:    ./start-dbus.sh"
echo "   2. Test connection: ./test-dbus.sh"
echo "   3. Stop daemon:     ./stop-dbus.sh"
echo ""
echo "💡 Environment variable for applications:"
echo "   export DBUS_SYSTEM_BUS_ADDRESS=\"unix:path=$SOCKET_DIR/system_bus_socket\""
echo ""