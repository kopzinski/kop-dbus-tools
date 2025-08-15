#!/usr/bin/env node

const dbus = require('dbus-next');

// DBus service configuration
const SERVICE_NAME = 'com.kopzinski.TestService';
const OBJECT_PATH = '/com/kopzinski/TestService';
const INTERFACE_NAME = 'com.kopzinski.KopzinskiInterface';

class KopzinskiInterface extends dbus.interface.Interface {
    constructor() {
        super(INTERFACE_NAME);
        
        // Properties
        this._version = '1.0.0';
        this._status = 'active';
        this._counter = 0;
        this._message = 'Hello from Kopzinski!';
        
        console.log('🚀 KopzinskiInterface initialized');
    }

    // Method: Get current status
    GetStatus() {
        console.log('📞 GetStatus() called');
        return this._status;
    }

    // Method: Set message
    SetMessage(message) {
        console.log(`📞 SetMessage("${message}") called`);
        this._message = message;
        
        // Emit signal when message changes
        this.MessageChanged(this._message);
        return true;
    }

    // Method: Get message
    GetMessage() {
        console.log('📞 GetMessage() called');
        return this._message;
    }

    // Method: Increment counter
    IncrementCounter() {
        console.log('📞 IncrementCounter() called');
        this._counter++;
        
        // Emit signal
        this.CounterChanged(this._counter);
        return this._counter;
    }

    // Method: Get counter value
    GetCounter() {
        console.log('📞 GetCounter() called');
        return this._counter;
    }

    // Method: Reset counter
    ResetCounter() {
        console.log('📞 ResetCounter() called');
        const oldValue = this._counter;
        this._counter = 0;
        
        // Emit signal
        this.CounterChanged(this._counter);
        return oldValue;
    }

    // Property: Version (read-only)
    get Version() {
        return this._version;
    }

    // Signal: Emitted when message changes
    MessageChanged(newMessage) {
        console.log(`📡 Signal: MessageChanged("${newMessage}")`);
        return newMessage;
    }

    // Signal: Emitted when counter changes
    CounterChanged(newValue) {
        console.log(`📡 Signal: CounterChanged(${newValue})`);
        return newValue;
    }
}

// Add method and signal definitions to the interface
KopzinskiInterface.configureMembers({
    methods: {
        GetStatus: {
            inSignature: '',
            outSignature: 's'
        },
        SetMessage: {
            inSignature: 's',
            outSignature: 'b'
        },
        GetMessage: {
            inSignature: '',
            outSignature: 's'
        },
        IncrementCounter: {
            inSignature: '',
            outSignature: 'i'
        },
        GetCounter: {
            inSignature: '',
            outSignature: 'i'
        },
        ResetCounter: {
            inSignature: '',
            outSignature: 'i'
        }
    },
    properties: {
        Version: {
            signature: 's',
            access: dbus.interface.ACCESS_READ
        }
    },
    signals: {
        MessageChanged: {
            signature: 's'
        },
        CounterChanged: {
            signature: 'i'
        }
    }
});

async function main() {
    try {
        console.log('🔧 Starting KopzinskiInterface DBus Service...');
        
        // Check if DBUS_SYSTEM_BUS_ADDRESS is set
        const dbusAddress = process.env.DBUS_SYSTEM_BUS_ADDRESS;
        if (!dbusAddress) {
            console.log('⚠️  DBUS_SYSTEM_BUS_ADDRESS not set, using default system bus');
        } else {
            console.log(`🔗 Using DBus address: ${dbusAddress}`);
        }

        // Connect to system bus
        const bus = dbus.systemBus();
        console.log('✅ Connected to system bus');

        // Create interface instance
        const kopzinskiInterface = new KopzinskiInterface();

        // Export the interface
        bus.export(OBJECT_PATH, kopzinskiInterface);
        console.log(`📤 Interface exported at object path: ${OBJECT_PATH}`);

        // Request service name
        await bus.requestName(SERVICE_NAME);
        console.log(`🏷️  Service name requested: ${SERVICE_NAME}`);

        console.log('');
        console.log('🎉 Service is running and ready!');
        console.log('');
        console.log('📋 Available methods:');
        console.log('   • GetStatus() → string');
        console.log('   • SetMessage(message) → boolean');
        console.log('   • GetMessage() → string');
        console.log('   • IncrementCounter() → int32');
        console.log('   • GetCounter() → int32');
        console.log('   • ResetCounter() → int32');
        console.log('');
        console.log('📋 Available properties:');
        console.log('   • Version (read-only) → string');
        console.log('');
        console.log('📋 Available signals:');
        console.log('   • MessageChanged(newMessage)');
        console.log('   • CounterChanged(newValue)');
        console.log('');
        console.log('🛑 Press Ctrl+C to stop the service');

        // Keep the service running
        process.on('SIGINT', () => {
            console.log('\\n🛑 Shutting down service...');
            process.exit(0);
        });

        // Emit a startup signal after 1 second
        setTimeout(() => {
            kopzinskiInterface.MessageChanged('Service started successfully!');
        }, 1000);

    } catch (error) {
        console.error('❌ Error starting service:', error);
        process.exit(1);
    }
}

// Run the service
if (require.main === module) {
    main().catch(console.error);
}

module.exports = { KopzinskiInterface, SERVICE_NAME, OBJECT_PATH, INTERFACE_NAME };