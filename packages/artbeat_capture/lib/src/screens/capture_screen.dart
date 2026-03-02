import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/advanced_camera_service.dart';
import 'capture_upload_screen.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Capture screen that uses AdvancedCameraService for custom camera UI
class CaptureScreen extends StatefulWidget {
  final bool isPicker;
  const CaptureScreen({Key? key, this.isPicker = false}) : super(key: key);

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final AdvancedCameraService _cameraService = AdvancedCameraService();
  bool _isInitializing = true;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() => _isInitializing = true);
    try {
      final success = await _cameraService.initialize();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'capture_camera_error_init'.tr(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppLogger.error('Camera initialization failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('capture_camera_error_generic'.tr(namedArgs: {'error': e.toString()}))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      final imagePath = await _cameraService.captureAdvancedImage();

      if (imagePath != null && mounted) {
        final imageFile = File(imagePath);
        if (widget.isPicker) {
          Navigator.of(context).pop(imageFile);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (context) =>
                  CaptureUploadScreen(initialImage: imageFile),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppLogger.error('Camera capture failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('capture_camera_error_take_picture'.tr()),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTakingPicture = false);
      }
    }
  }

  void _toggleFlash() {
    final currentMode = _cameraService.flashMode;
    FlashMode newMode;
    switch (currentMode) {
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        newMode = FlashMode.off;
        break;
    }
    _cameraService.setFlashMode(newMode);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (!_isInitializing &&
              _cameraService.isInitialized &&
              _cameraService.controller != null)
            Center(child: CameraPreview(_cameraService.controller!))
          else if (_isInitializing)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else
            Center(
              child: Text(
                'capture_camera_not_available'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            ),

          // Overlay Controls
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      IconButton(
                        icon: Icon(
                          _getFlashIcon(_cameraService.flashMode),
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: _toggleFlash,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 60), // Spacer for balance
                      // Capture Button
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: _isTakingPicture
                                  ? const CircularProgressIndicator(
                                      color: Colors.black,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),

                      // Switch Camera
                      IconButton(
                        icon: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () async {
                          await _cameraService.switchCamera();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFlashIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
    }
  }
}
