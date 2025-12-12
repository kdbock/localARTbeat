import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'capture_detail_screen.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Capture screen that goes straight to camera
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({Key? key}) : super(key: key);

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Open camera immediately when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCamera();
    });
  }

  Future<void> _openCamera() async {
    setState(() => _isProcessing = true);

    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        final imageFile = File(photo.path);
        // Automatically proceed to capture detail screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (context) => CaptureDetailScreen(imageFile: imageFile),
            ),
          );
        }
      } else {
        // User cancelled camera, go back
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        AppLogger.error('Camera capture failed: $e');

        // Show user-friendly error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getCameraErrorMessage(e)),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _openCamera,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _getCameraErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('permission')) {
      return 'Camera permission required. Please enable camera access in settings.';
    } else if (errorString.contains('camera not available') ||
        errorString.contains('no camera found')) {
      return 'Camera not available on this device.';
    } else if (errorString.contains('cancelled') ||
        errorString.contains('user_cancelled')) {
      return 'Camera capture was cancelled.';
    } else {
      return 'Unable to access camera. Please try again.';
    }
  }

  void _close() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Show loading indicator while processing
          if (_isProcessing)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'capture_screen_opening_camera'.tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),

          // Top bar with close button
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: _close,
            ),
          ),
        ],
      ),
    );
  }
}
