import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class AttachmentButton extends StatelessWidget {
  final void Function(XFile) onImageSelected;
  final void Function(XFile) onVideoSelected;
  final void Function(XFile) onFileSelected;

  const AttachmentButton({
    super.key,
    required this.onImageSelected,
    required this.onVideoSelected,
    required this.onFileSelected,
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.attach_file),
      onPressed: () => _showAttachmentOptions(context),
    );
  }
}
