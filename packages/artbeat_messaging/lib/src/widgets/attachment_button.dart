import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'voice_recorder_widget.dart';
import '../services/voice_recording_service.dart';

class AttachmentButton extends StatelessWidget {
  final void Function(XFile) onImageSelected;
  final void Function(XFile) onVideoSelected;
  final void Function(XFile) onFileSelected;
  final void Function(String voiceFilePath, Duration duration)? onVoiceRecorded;

  const AttachmentButton({
    super.key,
    required this.onImageSelected,
    required this.onVideoSelected,
    required this.onFileSelected,
    this.onVoiceRecorded,
  });

  Future<void> _showAttachmentOptions(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: Text('messaging_attachment_photo'.tr()),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  onImageSelected(image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: Text('messaging_attachment_video'.tr()),
              onTap: () async {
                Navigator.pop(context);
                final XFile? video = await picker.pickVideo(
                  source: ImageSource.gallery,
                );
                if (video != null) {
                  onVideoSelected(video);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text('messaging_attachment_file'.tr()),
              onTap: () async {
                Navigator.pop(context);
                // Implement file picking logic
              },
            ),
            if (onVoiceRecorded != null)
              ListTile(
                leading: const Icon(Icons.mic),
                title: Text('messaging_attachment_voice'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _showVoiceRecorder(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showVoiceRecorder(BuildContext context) async {
    final service = VoiceRecordingService();
    final capturedContext = context;

    try {
      // IMPORTANT: Check and request permissions BEFORE initializing the service
      // This ensures the native permission dialog appears before FlutterSound tries
      // to access the microphone
      log('🔐 Checking microphone permissions...');
      var permissionResult = await service.checkMicrophonePermission();
      log('🔍 Permission check result: $permissionResult');

      // If permission is denied (not permanently), request it
      if (permissionResult == PermissionResult.denied) {
        log('📱 Permission denied, requesting permission...');
        permissionResult = await service.requestMicrophonePermission();
        log('🔍 Permission request result: $permissionResult');
      }

      // If permanently denied, show settings dialog and return
      if (permissionResult == PermissionResult.permanentlyDenied) {
        log('🚫 Permission permanently denied, showing settings dialog');
        try {
          // ignore: use_build_context_synchronously
          _showPermissionSettingsDialog(capturedContext, service);
        } catch (e) {
          log('⚠️ Failed to show permission settings dialog: $e');
        }
        return;
      }

      // If still denied after request, return
      if (permissionResult != PermissionResult.granted) {
        log('❌ Permission not granted, cannot proceed');
        return;
      }

      // Now that we have permission, initialize the service
      log('🔧 Initializing voice recording service...');
      await service.initialize();
      log('✅ Voice recording service initialized');
    } catch (e) {
      log('❌ Failed to initialize voice recording service: $e');
      try {
        // ignore: use_build_context_synchronously
        _showInitializationErrorDialog(capturedContext);
      } catch (e) {
        log('⚠️ Failed to show initialization error dialog: $e');
      }
      return;
    }

    try {
      await showModalBottomSheet<void>(
        // ignore: use_build_context_synchronously
        context: capturedContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ChangeNotifierProvider.value(
          value: service,
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: VoiceRecorderWidget(
              onVoiceRecorded: (voiceFilePath, duration) {
                Navigator.pop(context);
                onVoiceRecorded?.call(voiceFilePath, duration);
              },
              onCancel: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      );
    } catch (e) {
      log('⚠️ Failed to show voice recorder modal: $e');
    }
  }

  void _showPermissionSettingsDialog(
    BuildContext context,
    VoiceRecordingService service,
  ) {
    try {
      showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('messaging_voice_permission_required'.tr()),
            content: Text('messaging_voice_permission_message'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('messaging_button_cancel'.tr()),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await openAppSettings();
                },
                child: Text('messaging_button_open_settings'.tr()),
              ),
            ],
          );
        },
      );
    } catch (e) {
      log('Error showing permission settings dialog: $e');
    }
  }

  void _showInitializationErrorDialog(BuildContext context) {
    try {
      showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('messaging_voice_unavailable'.tr()),
            content: Text('messaging_voice_unavailable_message'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('messaging_button_ok'.tr()),
              ),
            ],
          );
        },
      );
    } catch (e) {
      log('Error showing initialization error dialog: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.attach_file),
      onPressed: () => _showAttachmentOptions(context),
    );
  }
}
