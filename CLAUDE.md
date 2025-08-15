# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a DBus development toolkit providing shell scripts and Node.js examples for managing a local DBus system daemon. The project enables isolated DBus communication for development and testing, independent from the system's main DBus service.

## Architecture

- **Shell Scripts**: Core DBus daemon management (`start-dbus.sh`, `stop-dbus.sh`, `test-dbus.sh`)
- **Configuration**: Template-based config generation (`dbus-system-local.template.conf`)
- **Node.js Examples**: Complete DBus interface implementation in `nodejs/` directory
- **Setup Automation**: Platform-aware setup script with Arch Linux optimizations

## Essential Commands

### Initial Setup
```bash
./setup.sh                    # Generate config, create directories, make scripts executable
```

### DBus Daemon Management
```bash
./start-dbus.sh               # Start local DBus daemon
./stop-dbus.sh                # Stop daemon and cleanup
./test-dbus.sh                # Test connectivity and status
```

### Environment Configuration
```bash
export DBUS_SYSTEM_BUS_ADDRESS="unix:path=/tmp/dbus-system-local/system_bus_socket"
```

### Node.js Development
```bash
cd nodejs
npm install                   # Install dependencies
npm test                      # Run complete service + client test
npm run start-service         # Start KopzinskiInterface service
npm run test-client           # Run test client (requires service running)
```

## Key Implementation Details

### DBus Socket Location
- Socket: `/tmp/dbus-system-local/system_bus_socket`
- PID file: `/tmp/dbus-system-local/dbus.pid`
- Config: `./dbus-system-local.conf` (generated from template)

### Node.js Interface (KopzinskiInterface)
- Service name: `com.kopzinski.TestService`
- Object path: `/com/kopzinski/TestService`
- Interface: `com.kopzinski.KopzinskiInterface`
- Methods: GetStatus, SetMessage, GetMessage, IncrementCounter, GetCounter, ResetCounter
- Properties: Version (read-only)
- Signals: MessageChanged, CounterChanged

### Platform Support
- Linux (Ubuntu/Debian, Arch, RedHat/CentOS, Fedora, openSUSE)
- macOS (Homebrew)
- Arch Linux specific: dbus-broker detection, user group management

### Development Workflow
1. Run `./setup.sh` for initial environment setup
2. Start daemon with `./start-dbus.sh`
3. Set environment variable for applications
4. Develop/test with Node.js examples or custom applications
5. Use `./test-dbus.sh` to monitor daemon health
6. Stop with `./stop-dbus.sh` when finished

## Testing Strategy

The project uses `npm test` in the `nodejs/` directory which automatically:
1. Starts the DBus service in background
2. Waits 2 seconds for initialization
3. Runs comprehensive client tests covering all interface methods, properties, and signals

For manual testing, use `./test-dbus.sh` to verify daemon status, connectivity, and environment configuration.