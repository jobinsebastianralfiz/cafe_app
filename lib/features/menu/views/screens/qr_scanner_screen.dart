import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../admin/viewmodels/table_viewmodel.dart';

/// QR Scanner Screen for scanning table QR codes
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing || _hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? rawValue = barcode.rawValue;

    if (rawValue == null) return;

    // Extract table ID from QR code - support multiple formats
    String? tableId;

    // Format 1: Web URL - https://cafeapp-352be.web.app/table-bill?tableId={tableId}
    if (rawValue.contains('table-bill?tableId=')) {
      final uri = Uri.tryParse(rawValue);
      if (uri != null) {
        tableId = uri.queryParameters['tableId'];
      }
    }
    // Format 2: Deep link - cafeapp://table/{tableId}
    else if (rawValue.startsWith('cafeapp://table/')) {
      tableId = rawValue.replaceFirst('cafeapp://table/', '');
    }

    if (tableId == null || tableId.isEmpty) {
      _showErrorSnackBar('Invalid QR code. Please scan a table QR code.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _hasScanned = true;
    });

    // Validate table exists and is available
    final viewModel = ref.read(tableViewModelProvider.notifier);
    final table = await viewModel.getTableById(tableId);

    if (!mounted) return;

    if (table == null) {
      setState(() {
        _isProcessing = false;
        _hasScanned = false;
      });
      _showErrorSnackBar('Table not found. Please try again.');
      return;
    }

    if (!table.isActive) {
      setState(() {
        _isProcessing = false;
        _hasScanned = false;
      });
      _showErrorSnackBar('This table is currently inactive.');
      return;
    }

    // Set the selected table
    ref.read(selectedTableProvider.notifier).state = table;

    // Show success and navigate to menu
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${table.name} selected! Ready to order.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate to menu after a short delay (use push so back goes to home)
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      // Pop the scanner first, then push menu
      context.pop();
      context.push('/menu');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Table QR'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller?.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller?.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),

          // Overlay with scan area
          _buildScanOverlay(),

          // Instructions at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Point camera at the QR code on your table',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The QR code will automatically link your order to the table',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Verifying table...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.teal, width: 3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Corner decorations
            Positioned(
              top: 0,
              left: 0,
              child: _buildCorner(true, true),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: _buildCorner(true, false),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: _buildCorner(false, true),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: _buildCorner(false, false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Colors.white, width: 4)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Colors.white, width: 4)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Colors.white, width: 4)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Colors.white, width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }
}
