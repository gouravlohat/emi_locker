import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _scanned = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanBoxSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_off_rounded : Icons.flash_on_rounded),
            onPressed: () {
              setState(() => _torchOn = !_torchOn);
              _ctrl.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            onPressed: _ctrl.switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(
            controller: _ctrl,
            onDetect: _onDetect,
          ),

          // Overlay
          CustomPaint(
            size: Size.infinite,
            painter: _ScanOverlayPainter(
              boxSize: scanBoxSize,
              color: AppColors.primaryLight,
            ),
          ),

          // Corner brackets
          Center(
            child: SizedBox(
              width: scanBoxSize,
              height: scanBoxSize,
              child: const Stack(
                children: [
                  _Corner(alignment: Alignment.topLeft),
                  _Corner(alignment: Alignment.topRight, flipX: true),
                  _Corner(alignment: Alignment.bottomLeft, flipY: true),
                  _Corner(alignment: Alignment.bottomRight, flipX: true, flipY: true),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),
          ),

          // Instructions
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Align the QR code within the frame',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _scanned = true);
    _ctrl.stop();

    final data = barcode!.rawValue!;
    Navigator.pop(context, data);
  }
}

// ── Corner bracket widget ─────────────────────────────────────────────────────

class _Corner extends StatelessWidget {
  final Alignment alignment;
  final bool flipX;
  final bool flipY;

  const _Corner({
    required this.alignment,
    this.flipX = false,
    this.flipY = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.scale(
        scaleX: flipX ? -1 : 1,
        scaleY: flipY ? -1 : 1,
        child: CustomPaint(
          size: const Size(28, 28),
          painter: _CornerPainter(),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset.zero, Offset(size.width * 0.6, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height * 0.6), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Scan overlay painter ──────────────────────────────────────────────────────

class _ScanOverlayPainter extends CustomPainter {
  final double boxSize;
  final Color color;

  _ScanOverlayPainter({required this.boxSize, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(center: center, width: boxSize, height: boxSize);

    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    // Darken outside the scan box
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12))),
      ),
      bgPaint,
    );

    // Scan box border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
