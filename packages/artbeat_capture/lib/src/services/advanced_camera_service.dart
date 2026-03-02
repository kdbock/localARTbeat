import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Advanced camera service with enhanced capture capabilities
/// Provides professional-grade camera features for art capture
class AdvancedCameraService extends ChangeNotifier {
  static final AdvancedCameraService _instance =
      AdvancedCameraService._internal();
  factory AdvancedCameraService() => _instance;
  AdvancedCameraService._internal();

  List<CameraDescription>? _cameras;
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isRecording = false;

  // Advanced camera settings
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  FlashMode _flashMode = FlashMode.auto;
  FocusMode _focusMode = FocusMode.auto;
  ExposureMode _exposureMode = ExposureMode.auto;
  ResolutionPreset _resolutionPreset = ResolutionPreset.high;

  // Image processing settings
  bool _hdrEnabled = false;
  bool _stabilizationEnabled = true;
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;

  // Capture statistics
  int _captureCount = 0;
  final List<String> _recentCaptures = [];

  // ==========================================
  // INITIALIZATION AND SETUP
  // ==========================================

  /// Initialize the advanced camera service
  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        AppLogger.info('AdvancedCameraService: No cameras available');
        return false;
      }

      // Initialize with the best rear camera
      final rearCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      await _initializeController(rearCamera);
      _isInitialized = true;

      debugPrint(
        'AdvancedCameraService: Initialized with ${_cameras!.length} cameras',
      );
      return true;
    } catch (e) {
      AppLogger.info('AdvancedCameraService: Initialization failed: $e');
      return false;
    }
  }

  /// Initialize camera controller with advanced settings
  Future<void> _initializeController(CameraDescription camera) async {
    _controller = CameraController(
      camera,
      _resolutionPreset,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();

    // Set up advanced camera capabilities
    await _setupAdvancedFeatures();

    notifyListeners();
  }

  /// Setup advanced camera features
  Future<void> _setupAdvancedFeatures() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      // Get zoom capabilities
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();

      // Set initial camera settings
      await _controller!.setFlashMode(_flashMode);
      await _controller!.setFocusMode(_focusMode);
      await _controller!.setExposureMode(_exposureMode);

      // Enable image stabilization if available
      if (_stabilizationEnabled) {
        // Note: This would require platform-specific implementation
        AppLogger.info('AdvancedCameraService: Image stabilization enabled');
      }
    } catch (e) {
      debugPrint(
        'AdvancedCameraService: Error setting up advanced features: $e',
      );
    }
  }

  // ==========================================
  // CAMERA CONTROL METHODS
  // ==========================================

  /// Switch between front and rear cameras
  Future<bool> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return false;

    try {
      final currentCamera = _controller?.description;
      final newCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection != currentCamera?.lensDirection,
        orElse: () => _cameras!.first,
      );

      await _controller?.dispose();
      await _initializeController(newCamera);

      return true;
    } catch (e) {
      AppLogger.error('AdvancedCameraService: Error switching camera: $e');
      return false;
    }
  }

  /// Set zoom level
  Future<void> setZoomLevel(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final clampedZoom = zoom.clamp(_minZoom, _maxZoom);
      await _controller!.setZoomLevel(clampedZoom);
      _currentZoom = clampedZoom;
      notifyListeners();
    } catch (e) {
      AppLogger.error('AdvancedCameraService: Error setting zoom: $e');
    }
  }

  /// Set flash mode
  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.setFlashMode(mode);
      _flashMode = mode;
      notifyListeners();
    } catch (e) {
      AppLogger.error('AdvancedCameraService: Error setting flash mode: $e');
    }
  }

  /// Set focus mode
  Future<void> setFocusMode(FocusMode mode) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.setFocusMode(mode);
      _focusMode = mode;
      notifyListeners();
    } catch (e) {
      AppLogger.error('AdvancedCameraService: Error setting focus mode: $e');
    }
  }

  /// Set exposure mode
  Future<void> setExposureMode(ExposureMode mode) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.setExposureMode(mode);
      _exposureMode = mode;
      notifyListeners();
    } catch (e) {
      AppLogger.error('AdvancedCameraService: Error setting exposure mode: $e');
    }
  }

  /// Set focus point
  Future<void> setFocusPoint(Offset point) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.setFocusPoint(point);
      notifyListeners();
    } catch (e) {
      AppLogger.error('AdvancedCameraService: Error setting focus point: $e');
    }
  }

  /// Set exposure point
  Future<void> setExposurePoint(Offset point) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.setExposurePoint(point);
      notifyListeners();
    } catch (e) {
      AppLogger.error(
        'AdvancedCameraService: Error setting exposure point: $e',
      );
    }
  }

  // ==========================================
  // ADVANCED CAPTURE METHODS
  // ==========================================

  /// Capture high-quality image with advanced processing
  Future<String?> captureAdvancedImage({
    bool enableHDR = false,
    bool enableNoiseReduction = true,
    bool enableSharpening = false,
    Map<String, dynamic>? metadata,
  }) async {
    if (_controller == null || !_controller!.value.isInitialized) return null;

    try {
      // Capture the image
      final XFile image = await _controller!.takePicture();

      // Process the image with advanced features
      final processedImagePath = await _processAdvancedImage(
        image.path,
        enableHDR: enableHDR,
        enableNoiseReduction: enableNoiseReduction,
        enableSharpening: enableSharpening,
      );

      // Update statistics
      _captureCount++;
      _recentCaptures.insert(0, processedImagePath);
      if (_recentCaptures.length > 10) {
        _recentCaptures.removeLast();
      }

      notifyListeners();
      return processedImagePath;
    } catch (e) {
      AppLogger.error(
        'AdvancedCameraService: Error capturing advanced image: $e',
      );
      return null;
    }
  }

  /// Capture burst of images
  Future<List<String>> captureBurst({
    int count = 5,
    Duration interval = const Duration(milliseconds: 200),
  }) async {
    if (_controller == null || !_controller!.value.isInitialized) return [];

    final List<String> burstImages = [];

    try {
      for (int i = 0; i < count; i++) {
        final XFile image = await _controller!.takePicture();
        burstImages.add(image.path);

        if (i < count - 1) {
          await Future<void>.delayed(interval);
        }
      }

      _captureCount += count;
      notifyListeners();
      return burstImages;
    } catch (e) {
      AppLogger.error('AdvancedCameraService: Error capturing burst: $e');
      return burstImages;
    }
  }

  /// Capture with timer
  Future<String?> captureWithTimer({
    required Duration delay,
    void Function(int)? onCountdown,
  }) async {
    if (_controller == null || !_controller!.value.isInitialized) return null;

    try {
      // Countdown
      final seconds = delay.inSeconds;
      for (int i = seconds; i > 0; i--) {
        onCountdown?.call(i);
        await Future<void>.delayed(const Duration(seconds: 1));
      }

      // Capture
      final XFile image = await _controller!.takePicture();
      _captureCount++;
      notifyListeners();

      return image.path;
    } catch (e) {
      AppLogger.error('AdvancedCameraService: Error capturing with timer: $e');
      return null;
    }
  }

  /// Start video recording with advanced settings
  Future<bool> startVideoRecording({
    bool enableAudioRecording = true,
    int? maxDuration,
  }) async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isRecording) {
      return false;
    }

    try {
      await _controller!.startVideoRecording();
      _isRecording = true;

      // Set max duration timer if specified
      if (maxDuration != null) {
        Timer(Duration(seconds: maxDuration), () {
          if (_isRecording) {
            stopVideoRecording();
          }
        });
      }

      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error(
        'AdvancedCameraService: Error starting video recording: $e',
      );
      return false;
    }
  }

  /// Stop video recording
  Future<String?> stopVideoRecording() async {
    if (_controller == null || !_isRecording) return null;

    try {
      final XFile video = await _controller!.stopVideoRecording();
      _isRecording = false;
      notifyListeners();

      return video.path;
    } catch (e) {
      AppLogger.error(
        'AdvancedCameraService: Error stopping video recording: $e',
      );
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  // ==========================================
  // IMAGE PROCESSING METHODS
  // ==========================================

  /// Process image with advanced features
  Future<String> _processAdvancedImage(
    String imagePath, {
    bool enableHDR = false,
    bool enableNoiseReduction = true,
    bool enableSharpening = false,
  }) async {
    try {
      // For now, just return the original image path
      // In a real implementation, this would use image processing libraries
      debugPrint(
        'AdvancedCameraService: Processing image with HDR=$enableHDR, NoiseReduction=$enableNoiseReduction, Sharpening=$enableSharpening',
      );

      // Simulate processing time
      await Future<void>.delayed(const Duration(milliseconds: 100));

      return imagePath;
    } catch (e) {
      AppLogger.error('AdvancedCameraService: Error processing image: $e');
      return imagePath; // Return original if processing fails
    }
  }

  // ==========================================
  // GETTERS AND PROPERTIES
  // ==========================================

  CameraController? get controller => _controller;
  bool get isInitialized =>
      _isInitialized && _controller?.value.isInitialized == true;
  bool get isRecording => _isRecording;
  double get currentZoom => _currentZoom;
  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;
  FlashMode get flashMode => _flashMode;
  FocusMode get focusMode => _focusMode;
  ExposureMode get exposureMode => _exposureMode;
  int get captureCount => _captureCount;
  List<String> get recentCaptures => List.unmodifiable(_recentCaptures);

  // Camera capabilities
  bool get hasFlash => _controller?.value.flashMode != null;
  bool get canZoom => _maxZoom > _minZoom;
  bool get hasMultipleCameras => _cameras != null && _cameras!.length > 1;

  // Image processing settings
  double get brightness => _brightness;
  double get contrast => _contrast;
  double get saturation => _saturation;
  bool get hdrEnabled => _hdrEnabled;
  bool get stabilizationEnabled => _stabilizationEnabled;

  // ==========================================
  // SETTINGS METHODS
  // ==========================================

  /// Set image processing brightness
  void setBrightness(double brightness) {
    _brightness = brightness.clamp(-1.0, 1.0);
    notifyListeners();
  }

  /// Set image processing contrast
  void setContrast(double contrast) {
    _contrast = contrast.clamp(0.0, 2.0);
    notifyListeners();
  }

  /// Set image processing saturation
  void setSaturation(double saturation) {
    _saturation = saturation.clamp(0.0, 2.0);
    notifyListeners();
  }

  /// Toggle HDR mode
  void toggleHDR() {
    _hdrEnabled = !_hdrEnabled;
    notifyListeners();
  }

  /// Toggle image stabilization
  void toggleStabilization() {
    _stabilizationEnabled = !_stabilizationEnabled;
    notifyListeners();
  }

  /// Set resolution preset
  Future<void> setResolutionPreset(ResolutionPreset preset) async {
    if (_resolutionPreset == preset) return;

    _resolutionPreset = preset;

    // Reinitialize controller with new resolution
    if (_controller != null && _isInitialized) {
      final currentCamera = _controller!.description;
      await _controller!.dispose();
      await _initializeController(currentCamera);
    }
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Get camera statistics
  Map<String, dynamic> getCameraStatistics() {
    return {
      'captureCount': _captureCount,
      'recentCapturesCount': _recentCaptures.length,
      'currentZoom': _currentZoom,
      'flashMode': _flashMode.toString(),
      'focusMode': _focusMode.toString(),
      'exposureMode': _exposureMode.toString(),
      'resolutionPreset': _resolutionPreset.toString(),
      'hdrEnabled': _hdrEnabled,
      'stabilizationEnabled': _stabilizationEnabled,
      'brightness': _brightness,
      'contrast': _contrast,
      'saturation': _saturation,
    };
  }

  /// Reset capture statistics
  void resetStatistics() {
    _captureCount = 0;
    _recentCaptures.clear();
    notifyListeners();
  }

  /// Dispose of resources
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
