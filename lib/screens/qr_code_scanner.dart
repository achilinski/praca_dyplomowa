import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  String? scannedData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan QR Code")),
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.format == BarcodeFormat.qrCode) { // Only handle QR codes
              final String? code = barcode.rawValue;
              if (code != null) {
                setState(() {
                  scannedData = code;
                });
                Navigator.pop(context, scannedData);  // Return the scanned data
                break; // Exit after handling the first detected QR code
              }
            }
          }
        },
      ),
    );
  }
}
