import 'package:flutter/material.dart';

/// A widget to preview content
class ContentPreviewTile extends StatelessWidget {
  final String? title;
  final String? imageUrl;
  final VoidCallback? onTap;

  const ContentPreviewTile({super.key, this.title, this.imageUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: imageUrl != null
          ? Image.network(imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
          : const Icon(Icons.image),
      title: Text(title ?? 'Content'),
      onTap: onTap,
    );
  }
}
