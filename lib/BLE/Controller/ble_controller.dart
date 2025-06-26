import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class BleController extends GetxController {
  final serviceUuid = Guid("12345678-1234-5678-1234-56789abcdef0");
  final characteristicUuid = Guid("abcdefab-cdef-1234-5678-1234567890ab");

  final ssidController = TextEditingController();
  final passwordController = TextEditingController();

  RxList<BluetoothDevice> devicesList = <BluetoothDevice>[].obs;
  RxList<BluetoothDevice> connectedDevices = <BluetoothDevice>[].obs;
  Rx<BluetoothDevice?> connectedDevice = Rx<BluetoothDevice?>(null);
  RxBool isConnecting = false.obs;
  RxString status = ''.obs;
  Rx<BluetoothConnectionState> connectionState =
      BluetoothConnectionState.disconnected.obs;

  Future<void> requestPermissions() async {
    var statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetooth,
      Permission.locationWhenInUse,
    ].request();
    print('Permission statuses: $statuses');
  }

  Future<bool> isBluetoothOn() async {
    return await FlutterBluePlus.isOn;
  }

  Future<void> handleScan() async {
    print('Requesting permissions...');
    await requestPermissions();
    bool btOn = await isBluetoothOn();
    print('Bluetooth ON: $btOn');
    if (!btOn) {
      status.value = 'Bluetooth is off. Please turn it on.';
      return;
    }
    print('Starting scan...');
    startScan();
  }

  // Scan for BLE devices
  void startScan() {
    print('Clearing device list and starting scan...');
    devicesList.clear();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    FlutterBluePlus.scanResults.listen((results) {
      print('Scan results: \\${results.length}');
      for (ScanResult r in results) {
        print('Found device: \\${r.device.name} (\\${r.device.id})');
        if (!devicesList.any((d) => d.id == r.device.id)) {
          devicesList.add(r.device);
        }
      }
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  // Connect to a device
  Future<void> connectToDevice(BluetoothDevice device) async {
    isConnecting.value = true;
    status.value = 'Connecting...';

    try {
      await device.connect(autoConnect: false);
      connectedDevice.value = device;

      // Add to connected devices list if not already present
      if (!connectedDevices.any((d) => d.id == device.id)) {
        connectedDevices.add(device);
      }

      // Listen to connection state
      device.connectionState.listen((state) {
        connectionState.value = state;
        if (state == BluetoothConnectionState.connected) {
          status.value =
              'Connected to ${device.name.isNotEmpty ? device.name : device.id}';
        } else if (state == BluetoothConnectionState.disconnected) {
          status.value =
              'Disconnected from ${device.name.isNotEmpty ? device.name : device.id}';
          // Remove from connected devices when disconnected
          connectedDevices.removeWhere((d) => d.id == device.id);
          if (connectedDevice.value?.id == device.id) {
            connectedDevice.value = null;
          }
        }
      });

      // Explicitly check and set state after connect
      var state = await device.connectionState.first;
      connectionState.value = state;
      if (state == BluetoothConnectionState.connected) {
        status.value =
            'Connected to ${device.name.isNotEmpty ? device.name : device.id}';
      }
    } catch (e) {
      status.value = 'Connection failed: $e';
    } finally {
      isConnecting.value = false;
    }
  }

  // Send SSID and password to ESP32
  Future<void> sendCredentials() async {
    if (connectedDevice.value == null) return;
    final services = await connectedDevice.value!.discoverServices();
    for (var service in services) {
      if (service.uuid == serviceUuid) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == characteristicUuid) {
            final data = '${ssidController.text},${passwordController.text}';
            await characteristic.write(data.codeUnits);
            status.value = 'Credentials sent';
            return;
          }
        }
      }
    }
    status.value = 'Service/Characteristic not found';
  }

  void disconnect() {
    if (connectedDevice.value != null) {
      connectedDevice.value?.disconnect();
      connectedDevices.removeWhere((d) => d.id == connectedDevice.value!.id);
      connectedDevice.value = null;
      status.value = 'Disconnected';
    }
  }

  // Get connected devices count
  int getConnectedDevicesCount() {
    return connectedDevices.length;
  }

  // Get connected devices list
  List<BluetoothDevice> getConnectedDevices() {
    return connectedDevices.toList();
  }

  // Check if a specific device is connected
  bool isDeviceConnected(BluetoothDevice device) {
    return connectedDevices.any((d) => d.id == device.id);
  }

  // Get device connection status
  String getDeviceStatus(BluetoothDevice device) {
    if (isDeviceConnected(device)) {
      return 'Connected';
    } else {
      return 'Disconnected';
    }
  }

  // Clear all connected devices (useful for cleanup)
  void clearConnectedDevices() {
    for (var device in connectedDevices) {
      device.disconnect();
    }
    connectedDevices.clear();
    connectedDevice.value = null;
  }
}
