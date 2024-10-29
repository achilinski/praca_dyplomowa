import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:praca/screens/stop_work_screen.dart';

class QRScannerStopScreen extends StatefulWidget {
  @override
  _QRScannerStopScreenState createState() => _QRScannerStopScreenState();
}

class _QRScannerStopScreenState extends State<QRScannerStopScreen> {
  final MobileScannerController _controller = MobileScannerController(); // Controller to manage the scanner
  bool _isScanned = false; // Track if a code has been scanned

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan QR Code")),
      body: MobileScanner(
        controller: _controller,
        onDetect: (BarcodeCapture capture) {
          if (!_isScanned) { // Check if a code has already been scanned
            final Barcode? barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
            
            if (barcode != null && barcode.format == BarcodeFormat.qrCode) {
              final String? code = barcode.rawValue;
              if (code != null) {
                _isScanned = true; // Set flag to true to prevent further scans
                _controller.stop(); // Stop the camera

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StopWorkScreen(code: code),
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose of the controller when done
    super.dispose();
  }
}
