// 📁 lib/artbeat_profile/widgets/avatar_picker.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AvatarPicker extends StatefulWidget {
  final String? imageUrl;
  final void Function(File? imageFile) onImageSelected;

  const AvatarPicker({
    super.key,
    required this.onImageSelected,
    this.imageUrl,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      widget.onImageSelected(_selectedImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayImage = _selectedImage != null
        ? FileImage(_selectedImage!)
        : (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
            ? NetworkImage(widget.imageUrl!)
            : null;

    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: displayImage as ImageProvider<Object>?,
            child: displayImage == null
                ? const Icon(Icons.person, size: 48, color: Colors.grey)
                : null,
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.edit, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}
