# DBus Development Tools

A collection of shell scripts and examples to manage a local DBus system daemon for development purposes on Linux and macOS.

## TLDR

This toolkit provides a local DBus daemon for development, essential for Node.js applications using the `dbus-next` library. The library requires the `DBUS_SYSTEM_BUS_ADDRESS` environment variable to connect to a custom DBus daemon instead of the system one.

**Quick workflow for new environments:**
```bash
./setup.sh              # Initial setup
./start-dbus.sh          # Start local DBus daemon  
./test-dbus.sh           # Verify everything works
# Run your Node.js applications with dbus-next
./stop-dbus.sh           # Stop daemon when done
./clear-setup.sh         # Complete reset (removes all generated files)
```

## Overview

These tools provide an easy way to start, stop, and test a local DBus system daemon that runs independently from the system's main DBus service. This is useful for development and testing scenarios where you need isolated DBus communication.

The project includes:
- **Shell scripts** for DBus daemon management
- **Node.js examples** demonstrating custom DBus interface implementation
- **Setup automation** for easy environment configuration

## Prerequisites

- Linux or macOS operating system
- `dbus-daemon` command available:
  - **Linux (Ubuntu/Debian):** `sudo apt install dbus`
  - **Linux (Arch):** `sudo pacman -S dbus dbus-glib` (dbus-broker also supported)
  - **Linux (Fedora):** `sudo dnf install dbus`
  - **macOS:** `brew install dbus`
- Bash shell
- **For Node.js examples:** Node.js 14+ and npm
- **Arch Linux users:** May need to be in `dbus` group (`sudo usermod -a -G dbus $USER`)
- Optional: `socat` for enhanced connectivity testing

## Scripts

### `start-dbus.sh`
Starts a local DBus system daemon for development.

**Usage:**
```bash
./start-dbus.sh
```

**What it does:**
- Checks if a configuration file exists
- Verifies if DBus is already running
- Creates necessary directories
- Starts the DBus daemon with local configuration
- Provides connection instructions

**Output example:**
```
🚀 Starting local DBus system daemon...
📡 Starting daemon with configuration: /path/to/dbus-system-local.conf
✅ DBus daemon started successfully!
   PID: 12345
   Socket: /tmp/dbus-system-local/system_bus_socket

📋 To use with applications, configure environment variable:
   export DBUS_SYSTEM_BUS_ADDRESS="unix:path=/tmp/dbus-system-local/system_bus_socket"
```

### `stop-dbus.sh`
Stops the local DBus system daemon and cleans up temporary files.

**Usage:**
```bash
./stop-dbus.sh
```

**What it does:**
- Finds and terminates the DBus daemon process
- Removes temporary files (PID file, socket)
- Cleans up directories
- Handles orphaned processes gracefully

**Output example:**
```
🛑 Stopping local DBus system daemon...
💀 Killing DBus process (PID: 12345)...
✅ DBus process stopped successfully!
🧹 Cleaning temporary files...
🎉 DBus daemon stopped and cleanup completed!
```

### `test-dbus.sh`
Comprehensive testing and status checking of the local DBus daemon.

### `clear-setup.sh`
Completely resets the project to initial state by removing all generated files.

**Usage:**
```bash
./clear-setup.sh
```

**What it does:**
- Stops any running DBus daemon
- Removes generated configuration files
- Cleans temporary directories
- Returns project to clean state for redistribution

### `test-dbus.sh`
Comprehensive testing and status checking of the local DBus daemon.

**Usage:**
```bash
./test-dbus.sh
```

**What it does:**
- Checks process status and resource usage
- Verifies file existence (PID file, socket)
- Tests basic connectivity
- Lists available DBus interfaces (if dbus-send is available)
- Validates environment configuration
- Provides summary and recommendations

**Output sections:**
1. **Process Status** - Shows running daemon information
2. **File Status** - Verifies PID and socket files
3. **Connectivity Test** - Tests socket responsiveness
4. **Available DBus Interfaces** - Lists registered services
5. **Environment Configuration** - Checks environment variables
6. **Summary** - Overall status and recommendations

## Quick Start

### Setup Environment
1. **Run initial setup:**
   ```bash
   ./setup.sh
   ```
   This will:
   - Check for dbus-daemon installation
   - Generate configuration file with your username
   - Create necessary directories
   - Make scripts executable

2. **Start the daemon:**
   ```bash
   ./start-dbus.sh
   ```

3. **Configure your environment:**
   ```bash
   export DBUS_SYSTEM_BUS_ADDRESS="unix:path=/tmp/dbus-system-local/system_bus_socket"
   ```

4. **Test the setup:**
   ```bash
   ./test-dbus.sh
   ```

5. **When finished, stop the daemon:**
   ```bash
   ./stop-dbus.sh
   ```

6. **For complete cleanup (optional):**
   ```bash
   ./clear-setup.sh
   ```

### Try Node.js Examples
After setting up the DBus daemon:

1. **Navigate to Node.js examples:**
   ```bash
   cd nodejs
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Run the complete test:**
   ```bash
   npm test
   ```

This will start the KopzinskiInterface service and run a comprehensive test client that demonstrates all available methods, properties, and signals.

## Arch Linux Specific Notes

The tools have been optimized for Arch Linux with the following considerations:

### DBus Implementation
- **dbus-broker:** Arch uses dbus-broker by default (systemd integration)
- **dbus-daemon:** Also supported and recommended for development
- Both are automatically detected by the setup script

### Setup Requirements
1. **Install DBus:** `sudo pacman -S dbus dbus-glib`
2. **Enable service:** `sudo systemctl enable --now dbus`
3. **User groups:** `sudo usermod -a -G dbus $USER`
4. **Session restart:** Log out and back in after group changes

### Node.js Installation
- **Official repos:** `sudo pacman -S nodejs npm`
- **NVM (recommended):** `yay -S nvm` or direct install from nvm.sh
- **Version management:** Use nvm for multiple Node.js versions

### Troubleshooting
- **Permission issues:** Ensure you're in the `dbus` group
- **Service conflicts:** Check `systemctl status dbus-broker` vs `systemctl status dbus`
- **Socket permissions:** Verify `/tmp/dbus-system-local/` accessibility

The interactive guide (`./guide.sh`) provides Arch-specific instructions and troubleshooting tips.

## Project Structure

```
.
├── README.md                           # This file
├── setup.sh                          # Initial setup script
├── clear-setup.sh                    # Reset script (removes generated files)
├── start-dbus.sh                      # Start DBus daemon
├── stop-dbus.sh                       # Stop DBus daemon  
├── test-dbus.sh                       # Test and status check
├── dbus-system-local.template.conf    # Configuration template
├── dbus-system-local.conf             # Generated configuration (ignored by git)
└── nodejs/                            # Node.js examples
    ├── README.md                      # Node.js specific documentation
    ├── package.json                   # npm configuration
    ├── service.js                     # KopzinskiInterface DBus service
    └── client.js                      # Test client

```

## Node.js Examples

The `nodejs/` directory contains a complete example of implementing a custom DBus interface using Node.js. The `KopzinskiInterface` demonstrates:

### Features
- **Methods:** GetStatus, SetMessage, GetMessage, IncrementCounter, GetCounter, ResetCounter
- **Properties:** Version (read-only)
- **Signals:** MessageChanged, CounterChanged
- **Service Discovery:** Automatic registration with the local DBus daemon
- **Error Handling:** Comprehensive error handling and user feedback

### Use Cases
- **IPC Development:** Learn how to implement inter-process communication using DBus
- **Service Architecture:** Understand DBus service/client patterns
- **Signal Handling:** See how to emit and listen to DBus signals
- **Property Management:** Explore DBus property access patterns

See `nodejs/README.md` for detailed usage instructions and API documentation.

## Configuration

The setup script automatically generates `dbus-system-local.conf` from the template file `dbus-system-local.template.conf`, replacing the username placeholder with your current user.

## Environment Variables

### `DBUS_SYSTEM_BUS_ADDRESS`
Set this environment variable to use the local DBus daemon:
```bash
export DBUS_SYSTEM_BUS_ADDRESS="unix:path=/tmp/dbus-system-local/system_bus_socket"
```

## File Locations

- **Socket:** `/tmp/dbus-system-local/system_bus_socket`
- **PID file:** `/tmp/dbus-system-local/dbus.pid`
- **Configuration:** `./dbus-system-local.conf` (same directory as scripts)

## Troubleshooting

### DBus daemon won't start
- Ensure `dbus-daemon` is installed
- Check that the configuration file `dbus-system-local.conf` exists
- Verify you have write permissions to `/tmp/`

### Socket not created
- Check daemon logs for errors
- Ensure no other process is using the socket path
- Try restarting: `./stop-dbus.sh && ./start-dbus.sh`

### Permission issues
- Ensure scripts are executable: `chmod +x *.sh`
- Check file permissions in `/tmp/dbus-system-local/`

### Interface listing fails
- Install dbus tools: `sudo pacman -S dbus` (Arch) or `sudo apt install dbus` (Ubuntu/Debian)
- Check that `DBUS_SYSTEM_BUS_ADDRESS` is set correctly

## Tips

- Use `./test-dbus.sh` regularly to monitor daemon health
- The daemon runs independently from system DBus
- Safe to start/stop without affecting system services
- Temporary files are automatically cleaned up on stop

## Integration with Applications

To use the local DBus daemon in your applications:

1. Set the environment variable before running your application:
   ```bash
   export DBUS_SYSTEM_BUS_ADDRESS="unix:path=/tmp/dbus-system-local/system_bus_socket"
   your-application
   ```

2. Or set it inline:
   ```bash
   DBUS_SYSTEM_BUS_ADDRESS="unix:path=/tmp/dbus-system-local/system_bus_socket" your-application
   ```

## Security Note

This setup is intended for development and testing purposes only. The local daemon should not be used in production environments without proper security configuration.