# DBus System Daemon Scripts

A collection of shell scripts to manage a local DBus system daemon for development purposes on Linux.

## Overview

These scripts provide an easy way to start, stop, and test a local DBus system daemon that runs independently from the system's main DBus service. This is useful for development and testing scenarios where you need isolated DBus communication.

## Prerequisites

- Linux operating system
- `dbus-daemon` command available (install with `sudo pacman -S dbus` on Arch or `sudo apt install dbus` on Ubuntu/Debian)
- Bash shell
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

1. **Start the daemon:**
   ```bash
   ./start-dbus.sh
   ```

2. **Configure your environment:**
   ```bash
   export DBUS_SYSTEM_BUS_ADDRESS="unix:path=/tmp/dbus-system-local/system_bus_socket"
   ```

3. **Test the setup:**
   ```bash
   ./test-dbus.sh
   ```

4. **When finished, stop the daemon:**
   ```bash
   ./stop-dbus.sh
   ```

## Configuration

The scripts expect a configuration file named `dbus-system-local.conf` in the same directory. This file should contain the DBus daemon configuration for your local setup.

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