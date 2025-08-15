#!/usr/bin/env node

const dbus = require('dbus-next');

// DBus service configuration
const SERVICE_NAME = 'com.kopzinski.TestService';
const OBJECT_PATH = '/com/kopzinski/TestService';
const INTERFACE_NAME = 'com.kopzinski.KopzinskiInterface';

async function testKopzinskiInterface() {
    try {
        console.log('🔧 Connecting to KopzinskiInterface DBus Service...');
        
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

        // Get the service proxy object
        const proxyObject = await bus.getProxyObject(SERVICE_NAME, OBJECT_PATH);
        console.log('🎯 Got proxy object');

        // Get the interface
        const kopzinskiInterface = proxyObject.getInterface(INTERFACE_NAME);
        console.log('🔌 Got KopzinskiInterface');

        console.log('');
        console.log('🧪 Testing KopzinskiInterface...');
        console.log('=====================================');

        // Test 1: Get Version property
        console.log('\\n📝 Test 1: Getting Version property');
        const version = await kopzinskiInterface.Version;
        console.log(`   Version: ${version}`);

        // Test 2: Get initial status
        console.log('\\n📝 Test 2: Getting initial status');
        const status = await kopzinskiInterface.GetStatus();
        console.log(`   Status: ${status}`);

        // Test 3: Get initial message
        console.log('\\n📝 Test 3: Getting initial message');
        const initialMessage = await kopzinskiInterface.GetMessage();
        console.log(`   Initial Message: "${initialMessage}"`);

        // Test 4: Get initial counter
        console.log('\\n📝 Test 4: Getting initial counter');
        const initialCounter = await kopzinskiInterface.GetCounter();
        console.log(`   Initial Counter: ${initialCounter}`);

        // Test 5: Set new message
        console.log('\\n📝 Test 5: Setting new message');
        const newMessage = 'Hello from Node.js client!';
        const setResult = await kopzinskiInterface.SetMessage(newMessage);
        console.log(`   SetMessage result: ${setResult}`);
        
        // Verify message was set
        const updatedMessage = await kopzinskiInterface.GetMessage();
        console.log(`   Updated Message: "${updatedMessage}"`);

        // Test 6: Increment counter multiple times
        console.log('\\n📝 Test 6: Incrementing counter');
        for (let i = 1; i <= 3; i++) {
            const counterValue = await kopzinskiInterface.IncrementCounter();
            console.log(`   Increment ${i}: Counter = ${counterValue}`);
        }

        // Test 7: Get current counter
        console.log('\\n📝 Test 7: Getting current counter');
        const currentCounter = await kopzinskiInterface.GetCounter();
        console.log(`   Current Counter: ${currentCounter}`);

        // Test 8: Reset counter
        console.log('\\n📝 Test 8: Resetting counter');
        const oldCounterValue = await kopzinskiInterface.ResetCounter();
        console.log(`   Previous Counter Value: ${oldCounterValue}`);
        
        // Verify counter was reset
        const resetCounter = await kopzinskiInterface.GetCounter();
        console.log(`   Counter after reset: ${resetCounter}`);

        // Test 9: Listen to signals for a few seconds
        console.log('\\n📝 Test 9: Listening to signals for 3 seconds...');
        
        // Set up signal handlers
        kopzinskiInterface.on('MessageChanged', (newMessage) => {
            console.log(`   📡 Signal received - MessageChanged: "${newMessage}"`);
        });

        kopzinskiInterface.on('CounterChanged', (newValue) => {
            console.log(`   📡 Signal received - CounterChanged: ${newValue}`);
        });

        // Trigger some changes to generate signals
        setTimeout(async () => {
            await kopzinskiInterface.SetMessage('Testing signals!');
            await kopzinskiInterface.IncrementCounter();
            await kopzinskiInterface.IncrementCounter();
        }, 1000);

        // Wait for signals
        await new Promise(resolve => setTimeout(resolve, 3000));

        console.log('');
        console.log('🎉 All tests completed successfully!');
        console.log('=====================================');

    } catch (error) {
        console.error('❌ Error testing interface:', error.message);
        if (error.message.includes('ServiceUnknown')) {
            console.log('');
            console.log('💡 Make sure the service is running:');
            console.log('   cd nodejs && npm run start-service');
            console.log('');
            console.log('💡 Or run both service and client:');
            console.log('   cd nodejs && npm test');
        }
        process.exit(1);
    }
}

// Helper function to display usage
function showUsage() {
    console.log('');
    console.log('📋 KopzinskiInterface DBus Client');
    console.log('=================================');
    console.log('');
    console.log('This client tests the KopzinskiInterface DBus service.');
    console.log('');
    console.log('Usage:');
    console.log('   node client.js              - Run all tests');
    console.log('   npm run test-client          - Run all tests');
    console.log('');
    console.log('Prerequisites:');
    console.log('   1. Start the local DBus daemon: ../start-dbus.sh');
    console.log('   2. Set environment variable: export DBUS_SYSTEM_BUS_ADDRESS="unix:path=/tmp/dbus-system-local/system_bus_socket"');
    console.log('   3. Start the service: npm run start-service');
    console.log('');
}

// Main execution
if (require.main === module) {
    // Check for help argument
    if (process.argv.includes('--help') || process.argv.includes('-h')) {
        showUsage();
        process.exit(0);
    }

    testKopzinskiInterface().catch(console.error);
}