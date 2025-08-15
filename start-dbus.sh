#!/bin/bash

# Script to start local DBus system daemon for development
# Linux version - uses SYSTEM bus instead of SESSION

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/dbus-system-local.conf"
SOCKET_DIR="/tmp/dbus-system-local"
SOCKET_PATH="$SOCKET_DIR/system_bus_socket"
PID_FILE="$SOCKET_DIR/dbus.pid"

echo "🚀 Starting local DBus system daemon..."

# Check if configuration file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Check if DBus is already running
if [[ -f "$PID_FILE" ]]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "⚠️  DBus daemon is already running (PID: $PID)"
        echo "   Socket: $SOCKET_PATH"
        echo "   To stop: ./stop-dbus.sh"
        exit 0
    else
        echo "🧹 Removing obsolete PID file..."
        rm -f "$PID_FILE"
    fi
fi

# Create socket directory if it doesn't exist
mkdir -p "$SOCKET_DIR"

# Start DBus daemon
echo "📡 Starting daemon with configuration: $CONFIG_FILE"
DAEMON_OUTPUT=$(dbus-daemon --config-file="$CONFIG_FILE" --print-address --print-pid 2>&1)

if [[ $? -eq 0 ]]; then
    # Extract PID from output
    PID=$(echo "$DAEMON_OUTPUT" | tail -n 1)
    echo "$PID" > "$PID_FILE"
    
    # Wait a moment for socket to be created
    sleep 1
    
    if [[ -S "$SOCKET_PATH" ]]; then
        echo "✅ DBus daemon started successfully!"
        echo "   PID: $PID"
        echo "   Socket: $SOCKET_PATH"
        echo ""
        echo "📋 To use with applications, configure environment variable:"
        echo "   export DBUS_SYSTEM_BUS_ADDRESS=\"unix:path=$SOCKET_PATH\""
        echo ""
        echo "🔍 To check status:"
        echo "   ./test-dbus.sh"
        echo ""
        echo "🛑 To stop daemon:"
        echo "   ./stop-dbus.sh"
    else
        echo "❌ Error: Socket was not created at $SOCKET_PATH"
        exit 1
    fi
else
    echo "❌ Error starting DBus daemon:"
    echo "$DAEMON_OUTPUT"
    exit 1
fi