#!/bin/bash

# Script to test local DBus system daemon status
# Focused only on DBus daemon, agnostic to specific projects
# Linux version - uses SYSTEM bus instead of SESSION

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOCKET_DIR="/tmp/dbus-system-local"
SOCKET_PATH="$SOCKET_DIR/system_bus_socket"
PID_FILE="$SOCKET_DIR/dbus.pid"

echo "🔍 Testing local DBus system daemon status..."
echo ""

# ============================================================================
# 1. Process Verification
# ============================================================================
echo "📋 1. Process Status:"
DBUS_PROCESSES=$(ps aux | grep "dbus-daemon.*dbus-system-local.conf" | grep -v grep || true)

if [[ -n "$DBUS_PROCESSES" ]]; then
    echo "   ✅ DBus daemon running:"
    echo "$DBUS_PROCESSES" | while read -r line; do
        PID=$(echo "$line" | awk '{print $2}')
        CPU=$(echo "$line" | awk '{print $3}')
        MEM=$(echo "$line" | awk '{print $4}')
        UPTIME=$(ps -o etime= -p "$PID" | tr -d ' ')
        echo "      PID: $PID | CPU: $CPU% | MEM: $MEM% | Uptime: $UPTIME"
    done
else
    echo "   ❌ No running DBus daemon found"
fi

# ============================================================================
# 2. File Verification
# ============================================================================
echo ""
echo "📁 2. File Status:"

if [[ -f "$PID_FILE" ]]; then
    PID_CONTENT=$(cat "$PID_FILE")
    echo "   ✅ PID file exists: $PID_FILE (PID: $PID_CONTENT)"
    
    # Check if PID in file corresponds to running process
    if ps -p "$PID_CONTENT" > /dev/null 2>&1; then
        echo "      ✅ Valid PID - process is running"
    else
        echo "      ⚠️ Obsolete PID - process not found"
    fi
else
    echo "   ❌ PID file not found: $PID_FILE"
fi

if [[ -S "$SOCKET_PATH" ]]; then
    SOCKET_PERMS=$(ls -la "$SOCKET_PATH" | awk '{print $1 " " $3 ":" $4}')
    SOCKET_SIZE=$(ls -la "$SOCKET_PATH" | awk '{print $5}')
    echo "   ✅ Socket exists: $SOCKET_PATH"
    echo "      📋 Permissions: $SOCKET_PERMS"
else
    echo "   ❌ Socket not found: $SOCKET_PATH"
fi

# ============================================================================
# 3. Basic Connectivity Test
# ============================================================================
echo ""
echo "🔌 3. Connectivity Test:"

if [[ -S "$SOCKET_PATH" ]]; then
    # Teste simples usando timeout e echo para verificar se o socket responde
    if timeout 2s bash -c "echo '' > /dev/tcp/localhost/0 2>/dev/null" 2>/dev/null; then
        echo "   ✅ Socket responding"
    else
        # Alternative test checking if we can connect to socket
        if timeout 2s socat - "UNIX-CONNECT:$SOCKET_PATH" <<< "" >/dev/null 2>&1; then
            echo "   ✅ Socket accepting connections"
        elif command -v socat >/dev/null 2>&1; then
            echo "   ⚠️ Socket exists but may not be responding"
        else
            echo "   ℹ️ Socket exists (socat not available for connectivity test)"
        fi
    fi
else
    echo "   ❌ Socket not available for test"
fi

# ============================================================================
# 4. Interface Listing (using dbus-send if available)
# ============================================================================
echo ""
echo "🏷️  4. Available DBus Interfaces:"

if [[ -S "$SOCKET_PATH" ]] && command -v dbus-send >/dev/null 2>&1; then
    echo "   🔄 Querying interfaces via dbus-send..."
    
    # Configure environment temporarily
    export DBUS_SYSTEM_BUS_ADDRESS="unix:path=$SOCKET_PATH"
    
    # List available names on bus
    NAMES_RESULT=$(timeout 5s dbus-send --system --print-reply \
        --dest=org.freedesktop.DBus \
        /org/freedesktop/DBus \
        org.freedesktop.DBus.ListNames 2>/dev/null || echo "")
    
    if [[ -n "$NAMES_RESULT" ]]; then
        echo "   📋 Services registered on bus:"
        
        # Count total services
        TOTAL_SERVICES=$(echo "$NAMES_RESULT" | grep -c 'string ".*"' || echo "0")
        echo "      📊 Total services: $TOTAL_SERVICES"
        
        # List relevant services
        echo "$NAMES_RESULT" | grep -E 'string ".*"' | \
        sed 's/.*string "\(.*\)".*/\1/' | \
        sort | \
        while read -r name; do
            if [[ "$name" == "org.freedesktop.DBus" ]]; then
        echo "      🔧 $name (DBus Core)"
            elif [[ "$name" =~ ^org\.freedesktop\. ]]; then
        echo "      🔧 $name (System)"
            elif [[ "$name" =~ ^com\. ]]; then
        echo "      🎯 $name (Application)"
            elif [[ "$name" =~ ^: ]]; then
        echo "      🔗 $name (Temporary connection)"
            else
                echo "      📦 $name"
            fi
        done
    else
        echo "   ⚠️ Could not list interfaces (timeout or error)"
    fi
    
elif [[ -S "$SOCKET_PATH" ]]; then
    echo "   ⚠️ dbus-send not available to list interfaces"
    echo "      To install on Arch Linux: sudo pacman -S dbus"
    echo "      To install on Ubuntu/Debian: sudo apt install dbus"
    echo "      To install on MacOS: brew install dbus"
else
    echo "   ❌ Socket not available for interface test"
fi

# ============================================================================
# 5. Environment Configuration
# ============================================================================
echo ""
echo "🌍 5. Environment Configuration:"

if [[ -n "$DBUS_SYSTEM_BUS_ADDRESS" ]]; then
    if [[ "$DBUS_SYSTEM_BUS_ADDRESS" == "unix:path=$SOCKET_PATH" ]]; then
        echo "   ✅ DBUS_SYSTEM_BUS_ADDRESS configured correctly"
        echo "      $DBUS_SYSTEM_BUS_ADDRESS"
    else
        echo "   ⚠️ DBUS_SYSTEM_BUS_ADDRESS configured but pointing to another location:"
        echo "      Current: $DBUS_SYSTEM_BUS_ADDRESS"
        echo "      Expected: unix:path=$SOCKET_PATH"
    fi
else
    echo "   ❌ DBUS_SYSTEM_BUS_ADDRESS not configured"
    echo "      To configure: export DBUS_SYSTEM_BUS_ADDRESS=\"unix:path=$SOCKET_PATH\""
fi

# ============================================================================
# 6. Summary and Recommendations
# ============================================================================
echo ""
echo "📊 Summary:"

# Determine general status
DAEMON_OK="❌"
SOCKET_OK="❌"
CONFIG_OK="❌"

if [[ -n "$DBUS_PROCESSES" ]]; then
    DAEMON_OK="✅"
fi

if [[ -S "$SOCKET_PATH" ]]; then
    SOCKET_OK="✅"
fi

if [[ -n "$DBUS_SYSTEM_BUS_ADDRESS" ]] && [[ "$DBUS_SYSTEM_BUS_ADDRESS" == "unix:path=$SOCKET_PATH" ]]; then
    CONFIG_OK="✅"
fi

echo "   $DAEMON_OK Daemon running"
echo "   $SOCKET_OK Socket available"
echo "   $CONFIG_OK Environment variable configured"

if [[ "$DAEMON_OK" == "✅" ]] && [[ "$SOCKET_OK" == "✅" ]]; then
    echo ""
    echo "🎉 DBus is working correctly!"
    echo ""
    if [[ "$CONFIG_OK" == "❌" ]]; then
        echo "💡 To use in your projects, configure environment variable:"
        echo "   export DBUS_SYSTEM_BUS_ADDRESS=\"unix:path=$SOCKET_PATH\""
        echo ""
    fi
    echo "📝 Ready for use in any project that needs DBus system bus"
    
elif [[ "$DAEMON_OK" == "❌" ]]; then
    echo ""
    echo "🚀 To start DBus:"
    echo "   ./start-dbus.sh"
    
elif [[ "$SOCKET_OK" == "❌" ]]; then
    echo ""
    echo "🔄 To restart DBus:"
    echo "   ./stop-dbus.sh && ./start-dbus.sh"
fi

echo ""