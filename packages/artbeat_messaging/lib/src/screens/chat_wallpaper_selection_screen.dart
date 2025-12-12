import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatWallpaperSelectionScreen extends StatelessWidget {
  final String chatId;
  const ChatWallpaperSelectionScreen({Key? key, required this.chatId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder wallpapers
    final wallpapers = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.grey,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'messaging_chat_wallpaper_selection_text_select_wallpaper'.tr(),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: wallpapers.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () async {
              // Save selected wallpaper color value to Firestore
              await FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .set({
                    'wallpaper': wallpapers[index].toARGB32(),
                  }, SetOptions(merge: true));
              // ignore: use_build_context_synchronously
              Navigator.pop(context, wallpapers[index]);
            },
            child: Container(
              decoration: BoxDecoration(
                color: wallpapers[index],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.check, color: Colors.white, size: 48),
              ),
            ),
          );
        },
      ),
    );
  }
}
