import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanSchedulePage extends StatefulWidget {
  const ScanSchedulePage({super.key});

  @override
  State<ScanSchedulePage> createState() => _ScanSchedulePageState();
}

class _ScanSchedulePageState extends State<ScanSchedulePage> {
  final MobileScannerController _controller = MobileScannerController();
  String? scannedValue;

  Future<void> _saveScannedValue(String value) async {
    final prefs = await SharedPreferences.getInstance();

    // Get current list, or empty list if not set
    List<String> currentList = prefs.getStringList("friendSchedules") ?? [];

    // Add only if it’s not already in the list
    if (!currentList.contains(value)) {
      currentList.add(value);
      await prefs.setStringList("friendSchedules", currentList);
    }

    // Save updated list back
    await prefs.setStringList("friendSchedules", currentList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: scannedValue == null
            ? MobileScanner(
                controller: _controller,
                onDetect: (capture) async {
                  final barcode = capture.barcodes.first;
                  if (barcode.rawValue != null) {
                    final value = barcode.rawValue!;
                    setState(() {
                      scannedValue = value;
                    });

                    await _saveScannedValue(value);

                    _controller.stop(); // stop camera after first scan
                  }
                },
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 100),
                  const SizedBox(height: 20),
                  const Text("Added Schedule Successfully!"),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => scannedValue = null);
                      _controller.start(); // restart scanner
                    },
                    child: const Text("Scan Again"),
                  ),
                ],
              ),
      ),
    );
  }
}

