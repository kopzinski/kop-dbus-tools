#!/bin/bash

# Clear setup script for local DBus system daemon development environment
# Removes configuration files, directories, and shell profile entries created by setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/dbus-system-local.conf"
SOCKET_DIR="/tmp/dbus-system-local"

echo "🧹 Clearing local DBus system daemon environment..."
echo ""

# Stop daemon if running
if [[ -f "$SCRIPT_DIR/stop-dbus.sh" ]]; then
    echo "🛑 Stopping DBus daemon (if running)..."
    "$SCRIPT_DIR/stop-dbus.sh" 2>/dev/null || echo "ℹ️  No daemon was running"
fi

# Remove configuration file
if [[ -f "$CONFIG_FILE" ]]; then
    echo "🗑️  Removing configuration file: $CONFIG_FILE"
    rm -f "$CONFIG_FILE"
    echo "✅ Configuration file removed"
else
    echo "ℹ️  Configuration file not found: $CONFIG_FILE"
fi

# Remove socket directory
if [[ -d "$SOCKET_DIR" ]]; then
    echo "🗑️  Removing socket directory: $SOCKET_DIR"
    rm -rf "$SOCKET_DIR"
    echo "✅ Socket directory removed"
else
    echo "ℹ️  Socket directory not found: $SOCKET_DIR"
fi

# Remove environment variable from shell profiles
echo "🔧 Removing environment variable from shell profiles..."

# Detect shell and profile files (same logic as setup.sh)
SHELL_TYPE="$(basename "$SHELL")"
PROFILE_FILES=()

case "$SHELL_TYPE" in
    bash)
        [[ -f "$HOME/.bashrc" ]] && PROFILE_FILES+=("$HOME/.bashrc")
        [[ -f "$HOME/.bash_profile" ]] && PROFILE_FILES+=("$HOME/.bash_profile")
        ;;
    zsh)
        [[ -f "$HOME/.zshrc" ]] && PROFILE_FILES+=("$HOME/.zshrc")
        ;;
    *)
        echo "⚠️  Unknown shell: $SHELL_TYPE, checking .bashrc anyway"
        [[ -f "$HOME/.bashrc" ]] && PROFILE_FILES+=("$HOME/.bashrc")
        ;;
esac

# Remove DBus environment variable entries
REMOVED_FROM_PROFILE=false
for PROFILE_FILE in "${PROFILE_FILES[@]}"; do
    if [[ -f "$PROFILE_FILE" ]]; then
        if grep -q "# DBus development environment (added by kop-dbus-tools setup)" "$PROFILE_FILE"; then
            echo "📝 Removing DBus environment variable from $PROFILE_FILE"
            
            # Create backup
            cp "$PROFILE_FILE" "$PROFILE_FILE.backup.$(date +%Y%m%d_%H%M%S)"
            
            # Remove the comment line and the export line
            sed -i.tmp '/# DBus development environment (added by kop-dbus-tools setup)/d' "$PROFILE_FILE"
            sed -i.tmp '/export DBUS_SYSTEM_BUS_ADDRESS.*\/tmp\/dbus-system-local/d' "$PROFILE_FILE"
            
            # Remove the temporary file created by sed
            rm -f "$PROFILE_FILE.tmp"
            
            echo "✅ Environment variable removed from $PROFILE_FILE"
            REMOVED_FROM_PROFILE=true
        else
            echo "ℹ️  No DBus environment variable found in $PROFILE_FILE"
        fi
    fi
done

# Unset environment variable from current session
if [[ -n "$DBUS_SYSTEM_BUS_ADDRESS" ]] && [[ "$DBUS_SYSTEM_BUS_ADDRESS" == *"/tmp/dbus-system-local"* ]]; then
    echo "🔄 Unsetting environment variable from current session..."
    unset DBUS_SYSTEM_BUS_ADDRESS
    echo "✅ Environment variable unset from current session"
fi

# Clean up Node.js dependencies (optional)
if [[ -d "$SCRIPT_DIR/nodejs/node_modules" ]]; then
    read -p "🗑️  Remove Node.js dependencies in nodejs/node_modules? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing Node.js dependencies..."
        rm -rf "$SCRIPT_DIR/nodejs/node_modules"
        rm -f "$SCRIPT_DIR/nodejs/package-lock.json"
        echo "✅ Node.js dependencies removed"
    else
        echo "ℹ️  Node.js dependencies preserved"
    fi
fi

echo ""
echo "🎉 Clear setup complete!"
echo ""

if [[ "$REMOVED_FROM_PROFILE" == "true" ]]; then
    echo "📋 What was cleaned up:"
    echo "   ✓ Configuration file removed"
    echo "   ✓ Socket directory removed"
    echo "   ✓ Environment variable removed from shell profiles"
    echo "   ✓ Environment variable unset from current session"
    echo ""
    echo "💡 Backup files were created for modified shell profiles."
    echo "   Start a new terminal session for profile changes to take full effect."
else
    echo "📋 What was cleaned up:"
    echo "   ✓ Configuration file removed (if existed)"
    echo "   ✓ Socket directory removed (if existed)"
    echo "   ✓ Environment variable unset from current session"
fi
echo ""
echo "🔄 To setup again, run: ./setup.sh"
echo ""