import 'package:attendance_app/model/woman_model.dart';
import 'package:attendance_app/services/attendance_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  bool _isScanning = true;
  Woman? _scannedWoman;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Laser animation
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  Color primary = const Color(0xFFFF8F38);

  bool _isFlashOn = false;

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.unrestricted,
    detectionTimeoutMs: 100,
    torchEnabled: false,
    autoStart: true,
    returnImage: false,
  );

  @override
  void initState() {
    super.initState();
    // _checkCameraPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Forcefully remove any residual focus
      FocusManager.instance.primaryFocus?.unfocus();
    });
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0, end: 1).animate(_laserController);
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  // Future<void> _checkCameraPermission() async {
  //   var status = await Permission.camera.status;
  //   if (!status.isGranted) {
  //     status = await Permission.camera.request();
  //     if (!status.isGranted) {
  //       _showDialog('Permission Denied', 'Camera permission is required to scan barcodes.');
  //     }
  //   }
  // }

  Future<void> _handleBarcode(String barcodeValue) async {
    if (!_isScanning) return;
    setState(() => _isScanning = false);

    await Future.delayed(const Duration(milliseconds: 300)); // debounce

    // Search for woman with the scanned barcode
    final query = await _firestore
        .collection('women')
        .where('barcode', isEqualTo: barcodeValue)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      _showDialog('Not Found', 'No woman found with barcode: $barcodeValue');
      setState(() => _isScanning = true);
      return;
    }

    final doc = query.docs.first;
    final woman = Woman.fromMap(doc.data(), doc.id);
    _scannedWoman = woman;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showConfirmationDialog(woman);
    });
  }

  Future<void> _showConfirmationDialog(Woman woman) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Check if already marked present today
    final attendanceDoc = await _firestore
        .collection('attendance')
        .doc(today)
        .collection('entries')
        .doc(woman.id)
        .get();

    if (attendanceDoc.exists) {
      _showDialog('Duplicate', '${woman.name} is already marked present today.');
      setState(() {
        _scannedWoman = null;
        _isScanning = true;
      });
      return;
    }

    // Show Accept/Reject confirmation
    FocusScope.of(context).unfocus();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text('Confirm Attendance'),
          ],
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                child: Text(woman.name[0]),
                backgroundColor: Colors.orange.shade100,
              ),
              title: Text(woman.name, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(woman.husbandName),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 13.0, right: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📍 Address: ${woman.address}'),
                  const SizedBox(height: 4),
                  Text('🎟  Coupon: ${woman.couponCode}'),
                  const SizedBox(height: 4),
                  Text('🔢  Barcode: ${woman.barcode}'),
                ],
              ),
            )
          ],
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              setState(() {
                _scannedWoman = null;
                _isScanning = true;
              });
            },
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final timestamp = Timestamp.now();

              // Ensure parent attendance document exists
              await _firestore
                  .collection('attendance')
                  .doc(today)
                  .set({'exists': true}, SetOptions(merge: true));

              final entryData = {
                ...woman.toMap(), // Spread operator to include all fields from woman
                'timestamp': timestamp,
                'status': 'present',
                // 'date': DateTime.now(),
              };

              print('Saving to Firestore: $entryData');

              // Save to Firestore
              await _firestore
                  .collection('attendance')
                  .doc(today)
                  .collection('entries')
                  .doc(woman.id)
                  .set(entryData);

              // Save to local in-memory store
              AttendanceService().addEntry(entryData);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${woman.name} marked present.')),
              );

              // _showDialog('Success', '${woman.name} marked present.');
              setState(() {
                _scannedWoman = null;
                _isScanning = true;
              });
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _showDialog(String title, String message) {
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(
              title == 'Duplicate' ? Icons.warning_amber_rounded :
              title == 'Success' ? Icons.check_circle_outline :
              Icons.error_outline,
              color: title == 'Success'
                  ? Colors.green
                  : title == 'Duplicate'
                  ? Colors.orange
                  : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isScanning = true);
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanWidth = MediaQuery.of(context).size.width * 0.8;
    final scanHeight = MediaQuery.of(context).size.height * 0.3;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan Attendance'),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: GestureDetector(
                onTap: () {
                  setState(() => _isFlashOn = !_isFlashOn);
                  _controller.toggleTorch();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
          body: Stack(
          children: [
            MobileScanner(
                controller: _controller,
                scanWindow: Rect.fromCenter(
                  center: Offset(
                      MediaQuery.of(context).size.width / 2,
                      MediaQuery.of(context).size.height / 2),
                  width: scanWidth,
                  height: scanHeight,
                ),
                onDetect: (capture) {
                  for (final barcode in capture.barcodes) {
                    final code = barcode.rawValue;
                    if (code != null) {
                      _handleBarcode(code);
                      break;
                    }
                  }
                },
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: ScannerOverlayPainter(_laserAnimation),
                ),
              ),
            ),

            if (!_isScanning)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Animation<double> animation;

  ScannerOverlayPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final scanWidth = size.width * 0.8;
    final scanHeight = size.height * 0.3;
    final left = (size.width - scanWidth) / 2;
    final top = (size.height - scanHeight) / 2;
    final rect = Rect.fromLTWH(left, top, scanWidth, scanHeight);

    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.6);

    // Draw dark overlay outside scan area
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRRect(RRect.fromRectXY(rect, 20, 20)),
    );
    canvas.drawPath(path, overlayPaint);

    // Draw white border for scan area
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(RRect.fromRectXY(rect, 20, 20), borderPaint);

    // Red laser with gradient
    final laserGradient = Paint()
      ..shader = LinearGradient(
        colors: [Colors.red.withOpacity(0.1), Colors.red, Colors.red.withOpacity(0.1)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(left, top, scanWidth, scanHeight));

    final laserY = top + (animation.value * scanHeight);
    canvas.drawRect(Rect.fromLTWH(left, laserY, scanWidth, 3), laserGradient);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

