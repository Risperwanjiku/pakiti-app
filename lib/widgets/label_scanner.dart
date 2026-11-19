import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_colors.dart';
import '../utils/scan_filter.dart';

// The camera, with a frame to line the QR code up in. ScanFilter decides which
// readings count, so a label held in front of the camera counts once.
class LabelScanner extends StatefulWidget {
  const LabelScanner({
    super.key,
    required this.onScanned,
    required this.onTypeNumber,
    this.paused = false,
    this.height = 256,
    this.frame = 132,
    this.frameTop = 14,
    this.camera = true,
  });

  // gets the tracking number, like PKT-460048
  final ValueChanged<String> onScanned;
  final VoidCallback onTypeNumber;

  // true while the last scan is still being dealt with
  final bool paused;

  final double height;
  final double frame;
  final double frameTop;

  // false in tests, where there is no camera
  final bool camera;

  @override
  State<LabelScanner> createState() => _LabelScannerState();
}

class _LabelScannerState extends State<LabelScanner> {
  static const _button = Color(0xFF2E2A26);

  final _filter = ScanFilter();
  MobileScannerController? _controller;

  @override
  void initState() {
    super.initState();

    if (widget.camera) {
      _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _detected(BarcodeCapture capture) {
    final label = _filter.read(
      capture.barcodes.map((barcode) => barcode.rawValue),
      now: DateTime.now(),
      paused: widget.paused,
    );

    if (label != null) {
      widget.onScanned(label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (controller == null) ...[
            const ColoredBox(color: Colors.black),
            ..._buildFrame(),
          ] else ...[
            MobileScanner(
              controller: controller,
              onDetect: _detected,
              errorBuilder: (context, error) => _buildCameraError(error),
            ),
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, _) {
                if (state.error != null) {
                  return const SizedBox.shrink();
                }

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ..._buildFrame(),
                    if (state.torchState != TorchState.unavailable)
                      _buildTorch(controller, on: state.torchState == TorchState.on),
                  ],
                );
              },
            ),
          ],
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(child: _buildTypeNumber()),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFrame() {
    return [
      CustomPaint(
        painter: _FramePainter(size: widget.frame, top: widget.frameTop),
      ),
      Positioned(
        left: 24,
        right: 24,
        top: widget.frameTop + widget.frame + 18,
        child: const Text(
          'Point the camera at the QR code on the label',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            shadows: [Shadow(color: Color(0x99000000), blurRadius: 6)],
          ),
        ),
      ),
    ];
  }

  Widget _buildTorch(MobileScannerController controller, {required bool on}) {
    return Positioned(
      top: 12,
      right: 12,
      child: IconButton(
        tooltip: on ? 'Turn off the torch' : 'Turn on the torch',
        onPressed: controller.toggleTorch,
        style: IconButton.styleFrom(
          backgroundColor: _button,
          fixedSize: const Size(44, 44),
        ),
        icon: Icon(
          on ? Icons.flashlight_on : Icons.flashlight_off,
          size: 22,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTypeNumber() {
    return Material(
      color: _button,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTypeNumber,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.keyboard_outlined, size: 20, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Type the number instead',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraError(MobileScannerException error) {
    final message = error.errorCode == MobileScannerErrorCode.permissionDenied
        ? "Pakiti can't use the camera. Allow it in your phone's settings, or type the number."
        : "The camera didn't start. You can type the number instead.";

    return ColoredBox(
      color: AppColors.darkText,
      child: Padding(
        // leaves room for Type the number instead
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 56),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// the four white corners the QR code goes between
class _FramePainter extends CustomPainter {
  _FramePainter({required this.size, required this.top});

  final double size;
  final double top;

  @override
  void paint(Canvas canvas, Size area) {
    const corner = 26.0;
    const round = Radius.circular(14);
    final left = (area.width - size) / 2;
    final right = left + size;
    final bottom = top + size;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(left, top + corner)
      ..lineTo(left, top + 14)
      ..arcToPoint(Offset(left + 14, top), radius: round)
      ..lineTo(left + corner, top)
      ..moveTo(right - corner, top)
      ..lineTo(right - 14, top)
      ..arcToPoint(Offset(right, top + 14), radius: round)
      ..lineTo(right, top + corner)
      ..moveTo(right, bottom - corner)
      ..lineTo(right, bottom - 14)
      ..arcToPoint(Offset(right - 14, bottom), radius: round)
      ..lineTo(right - corner, bottom)
      ..moveTo(left + corner, bottom)
      ..lineTo(left + 14, bottom)
      ..arcToPoint(Offset(left, bottom - 14), radius: round)
      ..lineTo(left, bottom - corner);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) {
    return oldDelegate.size != size || oldDelegate.top != top;
  }
}