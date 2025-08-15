# KopzinskiInterface Node.js DBus Example

This example demonstrates how to use DBus with Node.js by creating a custom interface called `KopzinskiInterface`.

## Structure

- `service.js` - DBus service that implements the KopzinskiInterface
- `client.js` - Test client that interacts with the interface
- `package.json` - Node.js project configuration

## KopzinskiInterface

### Methods
- `GetStatus()` → string - Returns the current service status
- `SetMessage(message)` → boolean - Sets a custom message
- `GetMessage()` → string - Returns the current message
- `IncrementCounter()` → int32 - Increments counter and returns new value
- `GetCounter()` → int32 - Returns current counter value
- `ResetCounter()` → int32 - Resets counter and returns previous value

### Properties
- `Version` (read-only) → string - Interface version

### Signals
- `MessageChanged(newMessage)` - Emitted when message changes
- `CounterChanged(newValue)` - Emitted when counter changes

## How to use

### 1. Prepare environment
```bash
# Go back to root directory
cd ..

# Run setup (if not done yet)
./setup.sh

# Start local DBus daemon
./start-dbus.sh

# Set environment variable
export DBUS_SYSTEM_BUS_ADDRESS="unix:path=/tmp/dbus-system-local/system_bus_socket"
```

### 2. Install dependencies
```bash
cd nodejs
npm install
```

### 3. Run service
```bash
npm run start-service
```

### 4. Test interface (in another terminal)
```bash
# Set environment variable
export DBUS_SYSTEM_BUS_ADDRESS="unix:path=/tmp/dbus-system-local/system_bus_socket"

# Run test client
npm run test-client
```

### 5. Run everything automatically
```bash
npm test
```

## Programmatic usage example

```javascript
const dbus = require('dbus-next');

async function example() {
    const bus = dbus.systemBus();
    const proxyObject = await bus.getProxyObject(
        'com.kopzinski.TestService',
        '/com/kopzinski/TestService'
    );
    const interface = proxyObject.getInterface('com.kopzinski.KopzinskiInterface');
    
    // Use methods
    const status = await interface.GetStatus();
    await interface.SetMessage('Hello from code!');
    const counter = await interface.IncrementCounter();
    
    // Listen to signals
    interface.on('MessageChanged', (msg) => {
        console.log('New message:', msg);
    });
}
```