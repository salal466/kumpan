package org.netlabs.ktk.kumpankey

import android.bluetooth.*
import android.bluetooth.BluetoothGatt.GATT_SUCCESS
import android.content.Context
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

private val SERVICE_UUID        = UUID.fromString("0000180F-0000-1000-8000-00805f9b34fb")
private val CHARACTERISTIC_UUID = UUID.fromString("00002A19-0000-1000-8000-00805f9b34fb")
private val CCCD_UUID           = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

class MainActivity : FlutterActivity() {

    private var gattServer: BluetoothGattServer? = null
    private var batteryCharacteristic: BluetoothGattCharacteristic? = null
    private var batteryLevel: Int = 100
    private val subscribedDevices = mutableSetOf<BluetoothDevice>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "org.netlabs.ktk.kumpankey/bluetooth")
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
                    "startGattServer" -> {
                        batteryLevel = call.argument<Int>("batteryLevel") ?: 100
                        startGattServer()
                        result.success(null)
                    }
                    "stopGattServer" -> {
                        stopGattServer()
                        result.success(null)
                    }
                    "updateBatteryLevel" -> {
                        val level = call.argument<Int>("level") ?: return@setMethodCallHandler
                        batteryLevel = level
                        notifyBatteryLevel()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startGattServer() {
        val manager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

        val characteristic = BluetoothGattCharacteristic(
            CHARACTERISTIC_UUID,
            BluetoothGattCharacteristic.PROPERTY_READ or BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_READ
        ).also {
            it.addDescriptor(
                BluetoothGattDescriptor(
                    CCCD_UUID,
                    BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE
                )
            )
        }
        batteryCharacteristic = characteristic

        val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)
        service.addCharacteristic(characteristic)

        gattServer = manager.openGattServer(this, object : BluetoothGattServerCallback() {

            override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
                if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                    subscribedDevices.remove(device)
                }
            }

            override fun onCharacteristicReadRequest(
                device: BluetoothDevice, requestId: Int, offset: Int,
                characteristic: BluetoothGattCharacteristic
            ) {
                if (characteristic.uuid == CHARACTERISTIC_UUID) {
                    gattServer?.sendResponse(device, requestId, GATT_SUCCESS, 0,
                        byteArrayOf(batteryLevel.toByte()))
                } else {
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, 0, null)
                }
            }

            override fun onDescriptorWriteRequest(
                device: BluetoothDevice, requestId: Int,
                descriptor: BluetoothGattDescriptor, preparedWrite: Boolean,
                responseNeeded: Boolean, offset: Int, value: ByteArray
            ) {
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
        })

        gattServer?.addService(service)
    }

    private fun stopGattServer() {
        subscribedDevices.clear()
        gattServer?.close()
        gattServer = null
    }

    private fun notifyBatteryLevel() {
        val characteristic = batteryCharacteristic ?: return
        characteristic.value = byteArrayOf(batteryLevel.toByte())
        subscribedDevices.forEach { device ->
            gattServer?.notifyCharacteristicChanged(device, characteristic, false)
        }
    }

    override fun onDestroy() {
        stopGattServer()
        super.onDestroy()
    }
}
