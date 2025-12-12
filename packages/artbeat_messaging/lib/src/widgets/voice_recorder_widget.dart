import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../services/voice_recording_service.dart';
import '../theme/chat_theme.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final void Function(String voiceFilePath, Duration duration) onVoiceRecorded;
  final VoidCallback? onCancel;

  const VoiceRecorderWidget({
    super.key,
    required this.onVoiceRecorded,
    this.onCancel,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  bool _hasCheckedInitialPermission = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation for recording button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Wave animation for waveform
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    // Check permissions when widget is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialPermissions();
    });
  }

  Future<void> _checkInitialPermissions() async {
    if (_hasCheckedInitialPermission) return;
    _hasCheckedInitialPermission = true;

    final voiceService = Provider.of<VoiceRecordingService>(
      context,
      listen: false,
    );

    // Check current permission status
    var permissionResult = await voiceService.checkMicrophonePermission();

    log('🔍 Initial permission check result: $permissionResult');

    // If permission is denied (not permanently), request it immediately
    if (permissionResult == PermissionResult.denied) {
      log('📱 Permission denied, requesting permission on widget load...');
      permissionResult = await voiceService.requestMicrophonePermission();
      log('🔍 Initial permission request result: $permissionResult');
    }

    // Only show dialog if permission is permanently denied after request
    if (permissionResult == PermissionResult.permanentlyDenied) {
      if (mounted) {
        _showPermissionDeniedDialog(voiceService);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceRecordingService>(
      builder: (context, voiceService, child) {
        // Start/stop animations based on recording state
        if (voiceService.isRecording) {
          _pulseController.repeat(reverse: true);
          _waveController.repeat();
        } else {
          _pulseController.stop();
          _waveController.stop();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: ChatTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    voiceService.isRecording ? 'Recording...' : 'Voice Message',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (voiceService.isRecording || voiceService.hasRecording)
                    Text(
                      _formatDuration(voiceService.recordingDuration),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Waveform visualization
              if (voiceService.isRecording)
                _buildWaveform(voiceService.waveformData)
              else if (voiceService.hasRecording)
                _buildStaticWaveform()
              else
                _buildPlaceholderWaveform(),

              const SizedBox(height: 20),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  if (voiceService.isRecording || voiceService.hasRecording)
                    _buildControlButton(
                      icon: Icons.close,
                      onPressed: () async {
                        await voiceService.cancelRecording();
                        widget.onCancel?.call();
                      },
                      backgroundColor: Colors.red.withValues(alpha: 0.2),
                      iconColor: Colors.red,
                    ),

                  // Main record/stop button
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: voiceService.isRecording
                            ? _pulseAnimation.value
                            : 1.0,
                        child: _buildRecordButton(voiceService),
                      );
                    },
                  ),

                  // Send/Play button
                  if (voiceService.hasRecording && !voiceService.isRecording)
                    _buildControlButton(
                      icon: Icons.send,
                      onPressed: () async {
                        final path = voiceService.currentRecordingPath;
                        final duration = voiceService.recordingDuration;
                        if (path != null) {
                          widget.onVoiceRecorded(path, duration);
                        }
                      },
                      backgroundColor: Colors.green.withValues(alpha: 0.2),
                      iconColor: Colors.green,
                    )
                  else if (voiceService.hasRecording &&
                      !voiceService.isRecording)
                    _buildControlButton(
                      icon: Icons.play_arrow,
                      onPressed: () => voiceService.playRecording(),
                      backgroundColor: Colors.blue.withValues(alpha: 0.2),
                      iconColor: Colors.blue,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordButton(VoiceRecordingService voiceService) {
    return GestureDetector(
      onTap: () async {
        log(
          '🎤 Record button tapped! Current recording state: ${voiceService.isRecording}',
        );
        try {
          if (voiceService.isRecording) {
            log('🛑 Stopping recording...');
            await voiceService.stopRecording();
          } else {
            log('▶️ Starting recording...');

            // Check permissions first
            var permissionResult = await voiceService
                .checkMicrophonePermission();
            log('🔍 Permission check result: $permissionResult');

            // If permission is denied (not permanently), request it
            if (permissionResult == PermissionResult.denied) {
              log('📱 Permission denied, requesting permission...');
              permissionResult = await voiceService
                  .requestMicrophonePermission();
              log('🔍 Permission request result: $permissionResult');
            }

            // Handle permission results
            if (permissionResult == PermissionResult.permanentlyDenied) {
              log('🚫 Permission permanently denied, showing dialog');
              _showPermissionDeniedDialog(voiceService);
              return;
            } else if (permissionResult == PermissionResult.denied) {
              log('❌ Permission denied after request, showing error dialog');
              _showPermissionErrorDialog(permissionResult);
              return;
            } else if (permissionResult == PermissionResult.restricted) {
              log('⛔ Permission restricted, showing error dialog');
              _showPermissionErrorDialog(permissionResult);
              return;
            }

            log('✅ Permission granted, attempting to start recording');
            final success = await voiceService.startRecording();
            log('🎤 Recording start result: $success');

            if (!success) {
              log('❌ Recording failed to start, showing error dialog');
              _showRecordingErrorDialog();
            }
          }
        } catch (e) {
          log('❌ Error in record button: $e');
          _showRecordingErrorDialog();
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: voiceService.isRecording ? Colors.red : Colors.white,
          boxShadow: [
            BoxShadow(
              color: (voiceService.isRecording ? Colors.red : Colors.white)
                  .withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          voiceService.isRecording ? Icons.stop : Icons.mic,
          size: 40,
          color: voiceService.isRecording ? Colors.white : Colors.red,
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: () {
        log('🔘 Control button tapped: $icon');
        onPressed();
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        child: Icon(icon, size: 24, color: iconColor),
      ),
    );
  }

  Widget _buildWaveform(List<double> waveformData) {
    return SizedBox(
      height: 60,
      child: AnimatedBuilder(
        animation: _waveAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: WaveformPainter(
              waveformData: waveformData,
              color: Colors.white,
              animationValue: _waveAnimation.value,
            ),
            size: const Size(double.infinity, 60),
          );
        },
      ),
    );
  }

  Widget _buildStaticWaveform() {
    return SizedBox(
      height: 60,
      child: CustomPaint(
        painter: StaticWaveformPainter(color: Colors.white70),
        size: const Size(double.infinity, 60),
      ),
    );
  }

  Widget _buildPlaceholderWaveform() {
    return SizedBox(
      height: 60,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Container(
              width: 4,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _showPermissionDeniedDialog(VoiceRecordingService voiceService) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('messaging_voice_permission_required'.tr()),
          content: Text('messaging_voice_permission_message'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('messaging_button_cancel'.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: Text('messaging_button_open_settings'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionErrorDialog(PermissionResult result) {
    String title;
    String message;
    bool showSettingsButton = false;

    switch (result) {
      case PermissionResult.denied:
        title = 'Microphone Permission Denied';
        message =
            'ARTbeat needs microphone access to record voice messages. Please enable it in Settings.';
        showSettingsButton = true;
        break;
      case PermissionResult.restricted:
        title = 'Microphone Access Restricted';
        message =
            'Microphone access is restricted on this device. This may be due to parental controls or device management policies.';
        break;
      default:
        title = 'Microphone Access Required';
        message =
            'Unable to access microphone. Please check your device settings and ensure ARTbeat has microphone permission.';
        showSettingsButton = true;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('messaging_button_cancel'.tr()),
            ),
            if (showSettingsButton)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await openAppSettings();
                },
                child: Text('messaging_button_open_settings'.tr()),
              ),
          ],
        );
      },
    );
  }

  void _showRecordingErrorDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('messaging_voice_recording_error'.tr()),
          content: Text('messaging_voice_recording_error_message'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('messaging_button_ok'.tr()),
            ),
          ],
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color color;
  final double animationValue;

  WaveformPainter({
    required this.waveformData,
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / waveformData.length;
    final centerY = size.height / 2;

    for (int i = 0; i < waveformData.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final amplitude = waveformData[i];
      final barHeight = amplitude * size.height * 0.8;

      // Add animation effect
      final animatedHeight = barHeight * (0.5 + 0.5 * animationValue);

      canvas.drawLine(
        Offset(x, centerY - animatedHeight / 2),
        Offset(x, centerY + animatedHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class StaticWaveformPainter extends CustomPainter {
  final Color color;

  StaticWaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    const barCount = 20;
    final barWidth = size.width / barCount;

    // Generate a static waveform pattern
    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      final amplitude = (i % 3 == 0
          ? 0.8
          : i % 2 == 0
          ? 0.5
          : 0.3);
      final barHeight = amplitude * size.height * 0.6;

      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
