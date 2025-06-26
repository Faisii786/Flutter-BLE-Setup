import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controller/ble_controller.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleView extends StatelessWidget {
  BleView({super.key});
  final BleController controller = Get.put(BleController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLE to ESP32')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: controller.handleScan,
                  child: const Text('Scan'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: controller.stopScan,
                  child: const Text('Stop'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Obx(() => Text('Status: ${controller.status.value}')),
            const SizedBox(height: 10),
            Obx(
              () => Expanded(
                child: ListView.builder(
                  itemCount: controller.devicesList.length,
                  itemBuilder: (context, index) {
                    final device = controller.devicesList[index];
                    return ListTile(
                      title: Text(
                        device.name.isNotEmpty
                            ? device.name
                            : device.id.toString(),
                      ),
                      subtitle: Text(device.id.toString()),
                      trailing: ElevatedButton(
                        onPressed: controller.isConnecting.value
                            ? null
                            : () => controller.connectToDevice(device),
                        child: const Text('Connect'),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.ssidController,
              decoration: const InputDecoration(labelText: 'WiFi SSID'),
            ),
            TextField(
              controller: controller.passwordController,
              decoration: const InputDecoration(labelText: 'WiFi Password'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            Obx(
              () => ElevatedButton(
                onPressed:
                    controller.connectionState.value ==
                        BluetoothConnectionState.connected
                    ? controller.sendCredentials
                    : null,
                child: const Text('Send Credentials'),
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => controller.connectedDevice.value != null
                  ? ElevatedButton(
                      onPressed: controller.disconnect,
                      child: const Text('Disconnect'),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
