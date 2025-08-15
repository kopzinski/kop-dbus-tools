#!/bin/bash

# Script to stop local DBus system daemon
# Linux version - uses SYSTEM bus instead of SESSION

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOCKET_DIR="/tmp/dbus-system-local"
SOCKET_PATH="$SOCKET_DIR/system_bus_socket"
PID_FILE="$SOCKET_DIR/dbus.pid"

echo "🛑 Stopping local DBus system daemon..."

# Check if PID file exists
if [[ ! -f "$PID_FILE" ]]; then
    echo "⚠️  PID file not found. DBus may not be running."
    
    # Check if socket still exists
    if [[ -S "$SOCKET_PATH" ]]; then
        echo "🧹 Removing orphaned socket: $SOCKET_PATH"
        rm -f "$SOCKET_PATH"
    fi
    
    # Try to find running DBus processes
    DBUS_PROCESSES=$(ps aux | grep "dbus-daemon.*dbus-system-local.conf" | grep -v grep || true)
    if [[ -n "$DBUS_PROCESSES" ]]; then
        echo "🔍 Found running DBus processes:"
        echo "$DBUS_PROCESSES"
        
        # Extract PIDs and kill processes
        echo "$DBUS_PROCESSES" | awk '{print $2}' | while read -r pid; do
            echo "💀 Killing process PID: $pid"
            kill "$pid" 2>/dev/null || echo "   ⚠️  Could not kill process $pid"
        done
    else
        echo "✅ No running DBus processes found."
    fi
    
    exit 0
fi

# Read PID from file
PID=$(cat "$PID_FILE")

echo "📋 PID found: $PID"

# Check if process is running
if ps -p "$PID" > /dev/null 2>&1; then
    echo "💀 Killing DBus process (PID: $PID)..."
    
    # Try graceful stop first
    kill "$PID" 2>/dev/null
    
    # Wait a moment for process to terminate
    sleep 2
    
    # Check if process is still running
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "⚡ Forcing process stop..."
        kill -9 "$PID" 2>/dev/null || true
        sleep 1
    fi
    
    # Check if it really stopped
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "❌ Error: Could not stop process $PID"
        exit 1
    else
        echo "✅ DBus process stopped successfully!"
    fi
else
    echo "⚠️  Process $PID is no longer running."
fi

# Remove temporary files
echo "🧹 Cleaning temporary files..."

if [[ -f "$PID_FILE" ]]; then
    rm -f "$PID_FILE"
    echo "   ✓ Removed: $PID_FILE"
fi

if [[ -S "$SOCKET_PATH" ]]; then
    rm -f "$SOCKET_PATH"
    echo "   ✓ Removed: $SOCKET_PATH"
fi

# Remove directory if empty
if [[ -d "$SOCKET_DIR" ]] && [[ -z "$(ls -A "$SOCKET_DIR" 2>/dev/null)" ]]; then
    rmdir "$SOCKET_DIR"
    echo "   ✓ Removed directory: $SOCKET_DIR"
fi

echo ""
echo "🎉 DBus daemon stopped and cleanup completed!"
echo ""
echo "💡 To start again:"
echo "   ./start-dbus.sh"