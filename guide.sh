#!/bin/bash

# Interactive Guide for DBus Development Tools
# Step-by-step walkthrough with optional command execution

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_STEP=1
TOTAL_STEPS=8

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Progress indicators
CHECK_MARK="✅"
CROSS_MARK="❌"
ARROW="➤"
STEP_ICON="📋"

# Function to display header
show_header() {
    clear
    echo -e "${BOLD}${BLUE}================================================${NC}"
    echo -e "${BOLD}${BLUE}    DBus Development Tools - Interactive Guide${NC}"
    echo -e "${BOLD}${BLUE}================================================${NC}"
    echo -e "${CYAN}Progress: Step $CURRENT_STEP of $TOTAL_STEPS${NC}"
    echo ""
}

# Function to display step information
show_step() {
    local step_num=$1
    local title="$2"
    local description="$3"
    local command="$4"
    local is_optional="$5"
    
    echo -e "${BOLD}${STEP_ICON} Step $step_num: $title${NC}"
    echo -e "${description}"
    echo ""
    
    if [[ -n "$command" ]]; then
        echo -e "${YELLOW}Command to execute:${NC}"
        echo -e "${CYAN}$command${NC}"
        echo ""
    fi
    
    if [[ "$is_optional" == "true" ]]; then
        echo -e "${YELLOW}Note: This step is optional${NC}"
        echo ""
    fi
}

# Function to get user choice
get_user_choice() {
    local prompt="$1"
    local default="$2"
    
    echo -e "${prompt}"
    echo ""
    echo "Options:"
    echo "  [y/yes]  - Execute the command automatically"
    echo "  [s/show] - Show command for manual execution"
    echo "  [n/next] - Skip this step"
    echo "  [q/quit] - Exit guide"
    if [[ $CURRENT_STEP -gt 1 ]]; then
        echo "  [b/back] - Go back to previous step"
    fi
    echo ""
    
    while true; do
        read -p "Your choice [$default]: " choice
        choice=${choice:-$default}
        
        case "$choice" in
            y|yes|Y|YES)
                return 0 # Execute
                ;;
            s|show|S|SHOW)
                return 1 # Show only
                ;;
            n|next|N|NEXT)
                return 2 # Skip
                ;;
            q|quit|Q|QUIT)
                echo -e "${YELLOW}Guide cancelled by user${NC}"
                exit 0
                ;;
            b|back|B|BACK)
                if [[ $CURRENT_STEP -gt 1 ]]; then
                    return 3 # Go back
                else
                    echo "Cannot go back from first step"
                fi
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac
    done
}

# Function to execute command safely
execute_command() {
    local cmd="$1"
    local success_msg="$2"
    local error_msg="$3"
    
    echo -e "${YELLOW}Executing: $cmd${NC}"
    echo ""
    
    if eval "$cmd"; then
        echo ""
        echo -e "${GREEN}${CHECK_MARK} $success_msg${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}${CROSS_MARK} $error_msg${NC}"
        return 1
    fi
}

# Function to wait for user to continue
wait_continue() {
    echo ""
    read -p "Press Enter to continue..."
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect Linux distribution
detect_distro() {
    if [[ -f /etc/arch-release ]]; then
        echo "arch"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/redhat-release ]]; then
        echo "redhat"
    elif [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Function to check if user is in required groups (Arch specific)
check_user_groups() {
    local distro=$(detect_distro)
    if [[ "$distro" == "arch" ]]; then
        if ! groups | grep -q "\bdbus\b"; then
            echo -e "${YELLOW}Note: On Arch Linux, you may need to be in the 'dbus' group${NC}"
            echo -e "${YELLOW}If you encounter permission issues, run: sudo usermod -a -G dbus \$USER${NC}"
            echo -e "${YELLOW}Then log out and back in for the change to take effect.${NC}"
            echo ""
        fi
    fi
}

# Step functions
step_1_welcome() {
    show_header
    show_step 1 "Welcome to DBus Development Tools" \
        "This interactive guide will walk you through setting up and testing the DBus development environment.\n\nYou can choose to execute commands automatically or just see the commands for manual execution in another terminal." \
        "" "false"
    
    get_user_choice "Ready to start?" "y"
    case $? in
        0|1|2) CURRENT_STEP=2 ;;
        3) CURRENT_STEP=1 ;;
    esac
}

step_2_check_dependencies() {
    show_header
    local distro=$(detect_distro)
    
    # Check for both dbus-daemon and dbus-broker (Arch default)
    local check_cmd="command -v dbus-daemon && dbus-daemon --version | head -n1"
    if [[ "$distro" == "arch" ]]; then
        check_cmd="(command -v dbus-daemon && dbus-daemon --version | head -n1) || (command -v dbus-broker && echo 'dbus-broker found (Arch default)')"
    fi
    
    show_step 2 "Check Dependencies" \
        "First, let's check if DBus is installed on your system.\n\nNote: Arch Linux uses dbus-broker by default, but dbus-daemon is also supported." \
        "$check_cmd" "false"
    
    get_user_choice "Check for DBus installation?" "y"
    case $? in
        0) # Execute
            if execute_command "$check_cmd" \
                "DBus is installed and ready" \
                "DBus not found - please install it first"; then
                # Check user groups for Arch
                check_user_groups
                wait_continue
                CURRENT_STEP=3
            else
                echo ""
                echo -e "${YELLOW}Installation instructions:${NC}"
                echo "  Linux (Ubuntu/Debian): sudo apt install dbus"
                echo "  Linux (Arch):          sudo pacman -S dbus dbus-glib"
                echo "  Linux (Arch - AUR):    yay -S dbus-broker (if preferred)"
                echo "  macOS (Homebrew):      brew install dbus"
                echo ""
                if [[ "$distro" == "arch" ]]; then
                    echo -e "${CYAN}Arch Linux specific notes:${NC}"
                    echo "  • dbus-broker is the default, but dbus-daemon works too"
                    echo "  • Make sure you're in the 'dbus' group: sudo usermod -a -G dbus \$USER"
                    echo "  • You may need to enable dbus service: sudo systemctl enable --now dbus"
                fi
                wait_continue
                CURRENT_STEP=3
            fi
            ;;
        1) # Show only
            echo -e "${CYAN}${ARROW} Run this command in your terminal to check for dbus-daemon${NC}"
            wait_continue
            CURRENT_STEP=3
            ;;
        2) # Skip
            CURRENT_STEP=3
            ;;
        3) # Back
            CURRENT_STEP=1
            ;;
    esac
}

step_3_setup() {
    show_header
    show_step 3 "Run Initial Setup" \
        "The setup script will check dependencies, generate configuration with your username, and prepare the environment." \
        "./setup.sh" "false"
    
    get_user_choice "Run setup script?" "y"
    case $? in
        0) # Execute
            if execute_command "./setup.sh" \
                "Setup completed successfully" \
                "Setup failed - check the error messages above"; then
                wait_continue
                CURRENT_STEP=4
            else
                wait_continue
                CURRENT_STEP=4
            fi
            ;;
        1) # Show only
            echo -e "${CYAN}${ARROW} Run this command in your terminal to set up the environment${NC}"
            wait_continue
            CURRENT_STEP=4
            ;;
        2) # Skip
            CURRENT_STEP=4
            ;;
        3) # Back
            CURRENT_STEP=2
            ;;
    esac
}

step_4_start_daemon() {
    show_header
    show_step 4 "Start DBus Daemon" \
        "Now let's start the local DBus system daemon for development." \
        "./start-dbus.sh" "false"
    
    get_user_choice "Start DBus daemon?" "y"
    case $? in
        0) # Execute
            if execute_command "./start-dbus.sh" \
                "DBus daemon started successfully" \
                "Failed to start DBus daemon"; then
                wait_continue
                CURRENT_STEP=5
            else
                wait_continue
                CURRENT_STEP=5
            fi
            ;;
        1) # Show only
            echo -e "${CYAN}${ARROW} Run this command in your terminal to start the daemon${NC}"
            wait_continue
            CURRENT_STEP=5
            ;;
        2) # Skip
            CURRENT_STEP=5
            ;;
        3) # Back
            CURRENT_STEP=3
            ;;
    esac
}

step_5_environment() {
    show_header
    
    # Check if environment variable is already set
    if [[ -n "$DBUS_SYSTEM_BUS_ADDRESS" ]] && [[ "$DBUS_SYSTEM_BUS_ADDRESS" == *"/tmp/dbus-system-local"* ]]; then
        show_step 5 "Environment Variable Status" \
            "✅ Great! The DBUS_SYSTEM_BUS_ADDRESS environment variable is already set in this session.\n\nThe setup script automatically added it to your shell profile, so new terminal sessions will have it too.\n\nCurrent value: $DBUS_SYSTEM_BUS_ADDRESS" \
            "" "false"
        
        get_user_choice "Continue to testing?" "y"
        case $? in
            0|1|2) # Execute, Show, or Skip
                CURRENT_STEP=6
                ;;
            3) # Back
                CURRENT_STEP=4
                ;;
        esac
    else
        show_step 5 "Set Environment Variable" \
            "The setup script should have added the DBUS_SYSTEM_BUS_ADDRESS to your shell profile, but it's not set in this session.\n\nLet's set it manually for this terminal. New terminal sessions should have it automatically." \
            "export DBUS_SYSTEM_BUS_ADDRESS=\"unix:path=/tmp/dbus-system-local/system_bus_socket\"" "false"
        
        get_user_choice "Set environment variable for this session?" "y"
        case $? in
            0) # Execute
                if execute_command 'export DBUS_SYSTEM_BUS_ADDRESS="unix:path=/tmp/dbus-system-local/system_bus_socket"' \
                    "Environment variable set for this session" \
                    "Failed to set environment variable"; then
                    echo ""
                    echo -e "${YELLOW}Note: The setup script added this to your shell profile for future sessions.${NC}"
                    echo -e "${YELLOW}If you open new terminals, they should have it automatically.${NC}"
                    wait_continue
                    CURRENT_STEP=6
                else
                    wait_continue
                    CURRENT_STEP=6
                fi
                ;;
            1) # Show only
                echo -e "${CYAN}${ARROW} Run this command in your terminal:${NC}"
                echo ""
                echo -e "${YELLOW}Note: The setup script should have added this to your shell profile,${NC}"
                echo -e "${YELLOW}so new terminal sessions will have it automatically.${NC}"
                wait_continue
                CURRENT_STEP=6
                ;;
            2) # Skip
                CURRENT_STEP=6
                ;;
            3) # Back
                CURRENT_STEP=4
                ;;
        esac
    fi
}

step_6_test_daemon() {
    show_header
    show_step 6 "Test DBus Daemon" \
        "Let's test that the DBus daemon is running correctly and can accept connections." \
        "./test-dbus.sh" "false"
    
    get_user_choice "Test DBus daemon?" "y"
    case $? in
        0) # Execute
            if execute_command "./test-dbus.sh" \
                "DBus daemon test completed" \
                "DBus daemon test failed"; then
                wait_continue
                CURRENT_STEP=7
            else
                wait_continue
                CURRENT_STEP=7
            fi
            ;;
        1) # Show only
            echo -e "${CYAN}${ARROW} Run this command in your terminal to test the daemon${NC}"
            wait_continue
            CURRENT_STEP=7
            ;;
        2) # Skip
            CURRENT_STEP=7
            ;;
        3) # Back
            CURRENT_STEP=5
            ;;
    esac
}

step_7_nodejs_example() {
    show_header
    show_step 7 "Try Node.js Example" \
        "Now let's try the Node.js example that demonstrates a custom DBus interface.\n\nThis will install dependencies and run both a service and client." \
        "cd nodejs && npm install && npm test" "true"
    
    if ! command_exists "node"; then
        echo -e "${YELLOW}Note: Node.js is not installed. This step will show commands only.${NC}"
        echo ""
    fi
    
    get_user_choice "Try Node.js example?" "y"
    case $? in
        0) # Execute
            if command_exists "node"; then
                echo -e "${YELLOW}Changing to nodejs directory...${NC}"
                cd "$SCRIPT_DIR/nodejs"
                if execute_command "npm install" \
                    "Dependencies installed successfully" \
                    "Failed to install dependencies"; then
                    echo ""
                    echo -e "${YELLOW}Running the complete test (service + client)...${NC}"
                    execute_command "npm test" \
                        "Node.js example completed successfully" \
                        "Node.js example failed"
                fi
                cd "$SCRIPT_DIR"
                wait_continue
                CURRENT_STEP=8
            else
                echo -e "${RED}Node.js is not installed. Showing commands for manual execution.${NC}"
                echo ""
                local distro=$(detect_distro)
                echo -e "${CYAN}${ARROW} Install Node.js first:${NC}"
                case "$distro" in
                    "arch")
                        echo "  Arch Linux options:"
                        echo "    sudo pacman -S nodejs npm          # Official repos"
                        echo "    yay -S nvm                          # Via AUR (Node Version Manager)"
                        echo "    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash  # Direct nvm install"
                        ;;
                    "debian")
                        echo "  sudo apt install nodejs npm"
                        ;;
                    "macos")
                        echo "  brew install node"
                        ;;
                    *)
                        echo "  Check your distribution's package manager for nodejs/npm"
                        ;;
                esac
                echo ""
                echo -e "${CYAN}Then run these commands:${NC}"
                echo "  cd nodejs"
                echo "  npm install"
                echo "  npm test"
                wait_continue
                CURRENT_STEP=8
            fi
            ;;
        1) # Show only
            local distro=$(detect_distro)
            if ! command_exists "node"; then
                echo -e "${CYAN}${ARROW} Install Node.js first:${NC}"
                case "$distro" in
                    "arch")
                        echo "  sudo pacman -S nodejs npm          # Official repos"
                        echo "  # OR use NVM for version management:"
                        echo "  yay -S nvm && source ~/.bashrc && nvm install --lts"
                        ;;
                    "debian")
                        echo "  sudo apt install nodejs npm"
                        ;;
                    "macos")
                        echo "  brew install node"
                        ;;
                    *)
                        echo "  Check your distribution's package manager for nodejs/npm"
                        ;;
                esac
                echo ""
            fi
            echo -e "${CYAN}${ARROW} Run these commands in your terminal:${NC}"
            echo "  cd nodejs"
            echo "  npm install"
            echo "  npm test"
            echo ""
            echo -e "${YELLOW}Note: Make sure you have the environment variable set in that terminal:${NC}"
            echo '  export DBUS_SYSTEM_BUS_ADDRESS="unix:path=/tmp/dbus-system-local/system_bus_socket"'
            wait_continue
            CURRENT_STEP=8
            ;;
        2) # Skip
            CURRENT_STEP=8
            ;;
        3) # Back
            CURRENT_STEP=6
            ;;
    esac
}

step_8_completion() {
    show_header
    show_step 8 "Guide Complete!" \
        "🎉 Congratulations! You've successfully set up the DBus development environment.\n\n${BOLD}What you've accomplished:${NC}\n• Set up a local DBus system daemon\n• Configured your environment\n• Tested the daemon connectivity\n• (Optionally) Tried the Node.js example\n\n${BOLD}Next steps:${NC}\n• Explore the Node.js code in the nodejs/ directory\n• Try creating your own DBus interfaces\n• Use ./stop-dbus.sh when you're done\n\n${BOLD}Resources:${NC}\n• Read README.md for detailed documentation\n• Check nodejs/README.md for Node.js specific info\n• Use ./test-dbus.sh anytime to check daemon status" \
        "" "false"
    
    echo ""
    get_user_choice "Would you like to see cleanup instructions?" "n"
    case $? in
        0|1) # Execute or Show
            echo ""
            echo -e "${BOLD}${YELLOW}Cleanup Instructions:${NC}"
            echo "When you're done with development:"
            echo ""
            echo -e "${CYAN}1. Stop the DBus daemon:${NC}"
            echo "   ./stop-dbus.sh"
            echo ""
            echo -e "${CYAN}2. (Optional) Clean up completely:${NC}"
            echo "   ./clear-setup.sh    # Removes config, profile entries, and directories"
            echo ""
            echo -e "${YELLOW}Note: The environment variable was added to your shell profile by setup.sh${NC}"
            echo -e "${YELLOW}Use clear-setup.sh to remove it completely, or it will persist in new sessions.${NC}"
            echo ""
            echo -e "${GREEN}The daemon and temporary files will be cleaned up automatically by stop-dbus.sh${NC}"
            echo ""
            local distro=$(detect_distro)
            if [[ "$distro" == "arch" ]]; then
                echo -e "${BOLD}${CYAN}Arch Linux Troubleshooting Tips:${NC}"
                echo -e "${YELLOW}If you encounter issues:${NC}"
                echo "  • Check if you're in the dbus group: groups | grep dbus"
                echo "  • Ensure dbus service is running: systemctl status dbus"
                echo "  • For permission issues: sudo usermod -a -G dbus \$USER"
                echo "  • Check if dbus-broker conflicts: systemctl status dbus-broker"
                echo "  • Restart user session after group changes"
                echo ""
            fi
            wait_continue
            ;;
        2) # Skip cleanup info
            ;;
        3) # Back
            CURRENT_STEP=7
            return
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}${CHECK_MARK} Guide completed successfully!${NC}"
    echo -e "${BOLD}Thank you for using DBus Development Tools!${NC}"
    exit 0
}

# Main execution flow
main() {
    # Check if we're in the right directory
    if [[ ! -f "setup.sh" ]] || [[ ! -f "start-dbus.sh" ]]; then
        echo -e "${RED}Error: Please run this guide from the DBus tools directory${NC}"
        exit 1
    fi
    
    # Main loop
    while true; do
        case $CURRENT_STEP in
            1) step_1_welcome ;;
            2) step_2_check_dependencies ;;
            3) step_3_setup ;;
            4) step_4_start_daemon ;;
            5) step_5_environment ;;
            6) step_6_test_daemon ;;
            7) step_7_nodejs_example ;;
            8) step_8_completion ;;
            *) 
                echo -e "${RED}Invalid step: $CURRENT_STEP${NC}"
                exit 1
                ;;
        esac
    done
}

# Show usage if help requested
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "DBus Development Tools - Interactive Guide"
    echo ""
    echo "Usage: $0"
    echo ""
    echo "This interactive guide walks you through setting up and testing"
    echo "the DBus development environment step by step."
    echo ""
    echo "At each step, you can:"
    echo "  • Execute commands automatically"
    echo "  • See commands for manual execution"
    echo "  • Skip steps"
    echo "  • Navigate back and forth"
    echo ""
    exit 0
fi

# Run the guide
main