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
        # Detect specific Linux distribution
        if [[ -f /etc/arch-release ]]; then
            DISTRO="Arch"
        elif [[ -f /etc/debian_version ]]; then
            DISTRO="Debian/Ubuntu"
        elif [[ -f /etc/redhat-release ]]; then
            DISTRO="RedHat/CentOS"
        else
            DISTRO="Unknown"
        fi
        ;;
    Darwin*)
        PLATFORM="macOS"
        DISTRO="macOS"
        PACKAGE_MANAGERS=("brew")
        ;;
    *)
        echo "❌ Unsupported platform: $OS_TYPE"
        exit 1
        ;;
esac

echo "🖥️  Platform detected: $PLATFORM ($DISTRO)"

# Check if DBus is installed (daemon or broker)
echo "🔍 Checking for DBus installation..."
DBUS_FOUND=false
DBUS_TYPE=""

if command -v dbus-daemon >/dev/null 2>&1; then
    DBUS_VERSION=$(dbus-daemon --version | head -n1)
    echo "✅ Found dbus-daemon: $DBUS_VERSION"
    DBUS_FOUND=true
    DBUS_TYPE="daemon"
elif command -v dbus-broker >/dev/null 2>&1 && [[ "$DISTRO" == "Arch" ]]; then
    echo "✅ Found dbus-broker (Arch default)"
    echo "⚠️  Note: dbus-daemon is recommended for this development setup"
    DBUS_FOUND=true
    DBUS_TYPE="broker"
fi

if [[ "$DBUS_FOUND" == "false" ]]; then
    echo "❌ DBus not found!"
    echo ""
    echo "📦 Installation instructions:"
    
    case "$DISTRO" in
        "Arch")
            echo "   Arch Linux:    sudo pacman -S dbus dbus-glib"
            echo "   Alternative:   yay -S dbus-broker (AUR)"
            echo ""
            echo "📋 After installation on Arch:"
            echo "   • Enable dbus: sudo systemctl enable --now dbus"
            echo "   • Add to group: sudo usermod -a -G dbus \$USER"
            echo "   • Log out and back in"
            ;;
        "Debian/Ubuntu")
            echo "   Ubuntu/Debian: sudo apt-get install dbus"
            ;;
        *)
            case "$PLATFORM" in
                Linux)
                    echo "   CentOS/RHEL:   sudo yum install dbus"
                    echo "   Fedora:        sudo dnf install dbus"
                    echo "   openSUSE:      sudo zypper install dbus-1"
                    ;;
                macOS)
                    echo "   Homebrew:      brew install dbus"
                    echo "   MacPorts:      sudo port install dbus"
                    ;;
            esac
            ;;
    esac
    
    echo ""
    echo "⚠️  Please install DBus and run this setup again."
    exit 1
fi

# Check user groups on Arch
if [[ "$DISTRO" == "Arch" ]]; then
    echo "🔍 Checking user groups (Arch Linux)..."
    if ! groups | grep -q "\bdbus\b"; then
        echo "⚠️  You're not in the 'dbus' group"
        echo "💡 Recommendation: sudo usermod -a -G dbus $USER"
        echo "   Then log out and back in for the change to take effect."
    else
        echo "✅ User is in 'dbus' group"
    fi
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

# Setup environment variable in shell profile
echo "🔧 Setting up environment variable in shell profile..."
DBUS_ENV_VAR="export DBUS_SYSTEM_BUS_ADDRESS=\"unix:path=$SOCKET_DIR/system_bus_socket\""
COMMENT_LINE="# DBus development environment (added by kop-dbus-tools setup)"

# Detect shell and appropriate profile file
SHELL_TYPE="$(basename "$SHELL")"
PROFILE_FILES=()

case "$SHELL_TYPE" in
    bash)
        [[ -f "$HOME/.bashrc" ]] && PROFILE_FILES+=("$HOME/.bashrc")
        [[ -f "$HOME/.bash_profile" ]] && PROFILE_FILES+=("$HOME/.bash_profile")
        [[ ${#PROFILE_FILES[@]} -eq 0 ]] && PROFILE_FILES=("$HOME/.bashrc")
        ;;
    zsh)
        [[ -f "$HOME/.zshrc" ]] && PROFILE_FILES+=("$HOME/.zshrc")
        [[ ${#PROFILE_FILES[@]} -eq 0 ]] && PROFILE_FILES=("$HOME/.zshrc")
        ;;
    *)
        echo "⚠️  Unknown shell: $SHELL_TYPE, defaulting to .bashrc"
        PROFILE_FILES=("$HOME/.bashrc")
        ;;
esac

# Add environment variable to profile files
PROFILE_UPDATED=false
for PROFILE_FILE in "${PROFILE_FILES[@]}"; do
    if [[ -f "$PROFILE_FILE" ]] && grep -q "DBUS_SYSTEM_BUS_ADDRESS.*$SOCKET_DIR" "$PROFILE_FILE"; then
        echo "ℹ️  Environment variable already exists in $PROFILE_FILE"
    else
        echo "📝 Adding environment variable to $PROFILE_FILE"
        echo "" >> "$PROFILE_FILE"
        echo "$COMMENT_LINE" >> "$PROFILE_FILE"
        echo "$DBUS_ENV_VAR" >> "$PROFILE_FILE"
        echo "✅ Environment variable added to $PROFILE_FILE"
        PROFILE_UPDATED=true
    fi
done

# Source the profile to apply changes immediately
if [[ "$PROFILE_UPDATED" == "true" ]]; then
    echo "🔄 Applying changes to current session..."
    # Try to source the most appropriate profile file
    if [[ "$SHELL_TYPE" == "zsh" && -f "$HOME/.zshrc" ]]; then
        source "$HOME/.zshrc" 2>/dev/null || echo "⚠️  Could not source .zshrc automatically"
    elif [[ "$SHELL_TYPE" == "bash" ]]; then
        if [[ -f "$HOME/.bashrc" ]]; then
            source "$HOME/.bashrc" 2>/dev/null || echo "⚠️  Could not source .bashrc automatically"
        elif [[ -f "$HOME/.bash_profile" ]]; then
            source "$HOME/.bash_profile" 2>/dev/null || echo "⚠️  Could not source .bash_profile automatically"
        fi
    fi
    
    # Set the variable for this session regardless
    export DBUS_SYSTEM_BUS_ADDRESS="unix:path=$SOCKET_DIR/system_bus_socket"
    echo "✅ Environment variable is now active in this session"
fi

# Final check
echo ""
echo "🎉 Setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Start daemon:    ./start-dbus.sh"
echo "   2. Test connection: ./test-dbus.sh"
echo "   3. Stop daemon:     ./stop-dbus.sh"
echo ""
if [[ "$PROFILE_UPDATED" == "true" ]]; then
    echo "💡 Environment variable has been added to your shell profile and is active in this session."
else
    echo "💡 Environment variable was already configured in your shell profile."
    # Still export it for this session in case it's not already set
    export DBUS_SYSTEM_BUS_ADDRESS="unix:path=$SOCKET_DIR/system_bus_socket"
fi
echo ""