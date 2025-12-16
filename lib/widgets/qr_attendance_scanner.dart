import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sizer/sizer.dart';
import 'package:sabo_arena/utils/production_logger.dart';

class QRAttendanceScanner extends StatefulWidget {
  final String eventId;
  final String? sessionId;
  final Function(bool success, String message)? onScanComplete;

  const QRAttendanceScanner({
    Key? key,
    required this.eventId,
    this.sessionId,
    this.onScanComplete,
  }) : super(key: key);

  @override
  State<QRAttendanceScanner> createState() => _QRAttendanceScannerState();
}

class _QRAttendanceScannerState extends State<QRAttendanceScanner> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool isScanning = true;
  String? statusMessage;
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm danh QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              cameraController.torchEnabled ? Icons.flash_off : Icons.flash_on,
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 64,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Không thể truy cập camera',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              );
            },
          ),

          // Instructions
          Positioned(
            bottom: 15.h,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(3.w),
                ),
                child: Column(
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white, size: 8.w),
                    SizedBox(height: 1.h),
                    Text(
                      'Quét mã QR để điểm danh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Status message
          if (statusMessage != null)
            Positioned(
              bottom: 8.h,
              left: 4.w,
              right: 4.w,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: isProcessing ? Colors.blue[600] : Colors.green[600],
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Row(
                  children: [
                    if (isProcessing)
                      SizedBox(
                        width: 5.w,
                        height: 5.w,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        statusMessage!,
                        style: TextStyle(color: Colors.white, fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (!isScanning || isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() {
      isScanning = false;
      isProcessing = true;
      statusMessage = 'Đang xử lý...';
    });

    _processAttendanceQR(barcode.rawValue!);
  }

  Future<void> _processAttendanceQR(String qrData) async {
    try {
      ProductionLogger.info('🔍 Processing attendance QR: $qrData');

      // FEATURE NOT IMPLEMENTED: QR Attendance
      // TODO: Implement attendance logic with IntegratedQRService or AttendanceService
      // Showing user-friendly error message instead of broken functionality

      setState(() {
        statusMessage = 'Tính năng đang được phát triển';
        isProcessing = false;
      });

      if (widget.onScanComplete != null) {
        widget.onScanComplete!(
          false,
          'Tính năng QR điểm danh sẽ được ra mắt trong phiên bản tiếp theo',
        );
      }

      // Show user message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tính năng QR điểm danh đang được phát triển. Vui lòng quay lại sau!',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      /* ORIGINAL FAKE SUCCESS CODE - REMOVED
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        statusMessage = 'Điểm danh thành công!';
        isProcessing = false;
      });
      if (widget.onScanComplete != null) {
        widget.onScanComplete!(true, 'Điểm danh thành công');
      }
      */

      // Auto close after 2 seconds
      await Future.delayed(Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ProductionLogger.error('❌ Error processing attendance QR: $e', error: e);
      setState(() {
        statusMessage = 'Lỗi: $e';
        isProcessing = false;
        isScanning = true;
      });

      if (widget.onScanComplete != null) {
        widget.onScanComplete!(false, 'Lỗi: $e');
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
