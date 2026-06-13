package org.netlabs.ktk.kumpankey

import android.bluetooth.*
import android.bluetooth.BluetoothGatt.GATT_SUCCESS
import android.bluetooth.le.*
import android.content.Context
import android.os.ParcelUuid
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

private const val TAG = "KumpanBLE"

private val SERVICE_UUID        = UUID.fromString("0000180F-0000-1000-8000-00805f9b34fb")
private val CHARACTERISTIC_UUID = UUID.fromString("00002A19-0000-1000-8000-00805f9b34fb")
private val CCCD_UUID           = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

class MainActivity : FlutterActivity() {

    private var gattServer: BluetoothGattServer? = null
    private var batteryCharacteristic: BluetoothGattCharacteristic? = null
    private var batteryLevel: Int = 100
    private val subscribedDevices = mutableSetOf<BluetoothDevice>()
    private var isAdvertising = false
    private var isConnected = false

    // Flutter event sink for state updates
    private var stateEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method channel for commands
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "org.netlabs.ktk.kumpankey/bluetooth")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBluetoothName" -> {
                        val name = try {
                            val manager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
                            manager.adapter?.name
                        } catch (e: SecurityException) {
                            null
                        } ?: Settings.Secure.getString(contentResolver, "bluetooth_name")
                        result.success(name)
                    }
                    "start" -> {
                        batteryLevel = call.argument<Int>("batteryLevel") ?: 100
                        val success = startAll()
                        result.success(success)
                    }
                    "stop" -> {
                        stopAll()
                        result.success(true)
                    }
                    "updateBatteryLevel" -> {
                        val level = call.argument<Int>("level") ?: return@setMethodCallHandler
                        batteryLevel = level
                        notifyBatteryLevel()
                        result.success(null)
                    }
                    "getState" -> {
                        result.success(currentStateMap())
                    }
                    else -> result.notImplemented()
                }
            }

        // Event channel for real-time state updates
        EventChannel(flutterEngine.dartExecutor.binaryMessenger,
            "org.netlabs.ktk.kumpankey/state")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    stateEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    stateEventSink = null
                }
            })
    }

    /**
     * Start GATT server FIRST, then start BLE advertising.
     * Both must be native so Android coordinates them properly.
     */
    private fun startAll(): Boolean {
        try {
            val manager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            val adapter = manager.adapter
            if (adapter == null || !adapter.isEnabled) {
                Log.e(TAG, "Bluetooth adapter not available or not enabled")
                return false
            }

            // 1. Start GATT server
            startGattServer(manager)

            // 2. Start advertising
            startAdvertising(adapter)

            return true
        } catch (e: SecurityException) {
            Log.e(TAG, "Missing Bluetooth permission: ${e.message}")
            return false
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start: ${e.message}")
            return false
        }
    }

    private fun stopAll() {
        try {
            stopAdvertising()
            stopGattServer()
            isAdvertising = false
            isConnected = false
            emitState()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop: ${e.message}")
        }
    }

    // ─── GATT Server ──────────────────────────────────────────

    private fun startGattServer(manager: BluetoothManager) {
        // Build the Battery Level characteristic (Read + Notify)
        val characteristic = BluetoothGattCharacteristic(
            CHARACTERISTIC_UUID,
            BluetoothGattCharacteristic.PROPERTY_READ or
                    BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_READ
        ).also {
            it.addDescriptor(
                BluetoothGattDescriptor(
                    CCCD_UUID,
                    BluetoothGattDescriptor.PERMISSION_READ or
                            BluetoothGattDescriptor.PERMISSION_WRITE
                )
            )
            // Set initial value
            it.value = byteArrayOf(batteryLevel.toByte())
        }
        batteryCharacteristic = characteristic

        // Build the Battery Service
        val service = BluetoothGattService(
            SERVICE_UUID,
            BluetoothGattService.SERVICE_TYPE_PRIMARY
        )
        service.addCharacteristic(characteristic)

        // Open the server with callbacks
        gattServer = manager.openGattServer(this, gattCallback)
        gattServer?.addService(service)

        Log.i(TAG, "GATT server started with Battery Service")
    }

    private val gattCallback = object : BluetoothGattServerCallback() {

        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            Log.i(TAG, "Connection state: device=${device.address}, newState=$newState")
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                isConnected = true
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                subscribedDevices.remove(device)
                // Check if any device is still connected
                isConnected = subscribedDevices.isNotEmpty()
            }
            runOnUiThread { emitState() }
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice, requestId: Int, offset: Int,
            characteristic: BluetoothGattCharacteristic
        ) {
            Log.i(TAG, "Characteristic read: uuid=${characteristic.uuid}, device=${device.address}")
            if (characteristic.uuid == CHARACTERISTIC_UUID) {
                gattServer?.sendResponse(
                    device, requestId, GATT_SUCCESS, 0,
                    byteArrayOf(batteryLevel.toByte())
                )
            } else {
                gattServer?.sendResponse(
                    device, requestId, BluetoothGatt.GATT_FAILURE, 0, null
                )
            }
        }

        override fun onDescriptorReadRequest(
            device: BluetoothDevice, requestId: Int, offset: Int,
            descriptor: BluetoothGattDescriptor
        ) {
            Log.i(TAG, "Descriptor read: uuid=${descriptor.uuid}")
            if (descriptor.uuid == CCCD_UUID) {
                val value = if (subscribedDevices.contains(device)) {
                    BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                } else {
                    BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
                }
                gattServer?.sendResponse(device, requestId, GATT_SUCCESS, 0, value)
            } else {
                gattServer?.sendResponse(device, requestId, GATT_SUCCESS, 0, null)
            }
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice, requestId: Int,
            descriptor: BluetoothGattDescriptor, preparedWrite: Boolean,
            responseNeeded: Boolean, offset: Int, value: ByteArray
        ) {
            Log.i(TAG, "Descriptor write: uuid=${descriptor.uuid}, device=${device.address}")
            if (descriptor.uuid == CCCD_UUID) {
                if (value.contentEquals(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)) {
                    subscribedDevices.add(device)
                } else {
                    subscribedDevices.remove(device)
                }
            }
            if (responseNeeded) {
                gattServer?.sendResponse(device, requestId, GATT_SUCCESS, 0, null)
            }
        }

        override fun onServiceAdded(status: Int, service: BluetoothGattService) {
            Log.i(TAG, "Service added: uuid=${service.uuid}, status=$status")
        }
    }

    private fun stopGattServer() {
        subscribedDevices.clear()
        gattServer?.close()
        gattServer = null
        batteryCharacteristic = null
        Log.i(TAG, "GATT server stopped")
    }

    private fun notifyBatteryLevel() {
        val char = batteryCharacteristic ?: return
        char.value = byteArrayOf(batteryLevel.toByte())
        subscribedDevices.forEach { device ->
            try {
                gattServer?.notifyCharacteristicChanged(device, char, false)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to notify ${device.address}: ${e.message}")
            }
        }
    }

    // ─── BLE Advertising ──────────────────────────────────────

    private var advertiser: BluetoothLeAdvertiser? = null

    private fun startAdvertising(adapter: BluetoothAdapter) {
        advertiser = adapter.bluetoothLeAdvertiser
        if (advertiser == null) {
            Log.e(TAG, "BLE Advertiser not available")
            return
        }

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setConnectable(true)
            .setTimeout(0)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
            .build()

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(true)
            .setIncludeTxPowerLevel(true)
            .addServiceUuid(ParcelUuid(SERVICE_UUID))
            .build()

        advertiser?.startAdvertising(settings, data, advertiseCallback)
        Log.i(TAG, "BLE advertising started")
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            Log.i(TAG, "Advertising started successfully")
            isAdvertising = true
            runOnUiThread { emitState() }
        }

        override fun onStartFailure(errorCode: Int) {
            Log.e(TAG, "Advertising failed with error code: $errorCode")
            isAdvertising = false
            runOnUiThread { emitState() }
        }
    }

    private fun stopAdvertising() {
        try {
            advertiser?.stopAdvertising(advertiseCallback)
        } catch (e: Exception) {
            Log.e(TAG, "Stop advertising error: ${e.message}")
        }
        advertiser = null
        Log.i(TAG, "BLE advertising stopped")
    }

    // ─── State management ─────────────────────────────────────

    private fun currentStateMap(): Map<String, Any> {
        return mapOf(
            "isAdvertising" to isAdvertising,
            "isConnected" to isConnected,
        )
    }

    private fun emitState() {
        stateEventSink?.success(currentStateMap())
    }

    override fun onDestroy() {
        stopAll()
        super.onDestroy()
    }
}
