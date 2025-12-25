import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ProfilePictureViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String userId;

  const ProfilePictureViewerScreen({
    super.key,
    required this.imageUrl,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          alignment: Alignment.topLeft,
          children: [
            Hero(
              tag: 'user_avatar_$userId',
              child: PhotoView(
                imageProvider: NetworkImage(imageUrl),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                minScale: PhotoViewComputedScale.contained * 1.0,
                maxScale: PhotoViewComputedScale.covered * 2.0,
              ),
            ),
            SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
