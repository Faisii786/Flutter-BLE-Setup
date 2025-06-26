import 'package:flutter/material.dart';
import 'BLE/View/ble_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BLE TO ESP32',
      home: BleView(),
    );
  }
}

Future<void> requestPermissions() async {
  await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.bluetooth,
    Permission.locationWhenInUse,
  ].request();
}

Future<bool> isBluetoothOn() async {
  return await FlutterBluePlus.isOn;
}
