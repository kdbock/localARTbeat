import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';

class _ArtistAutocompleteDialog extends StatefulWidget {
  final UserService userService;
  const _ArtistAutocompleteDialog({required this.userService});

  @override
  State<_ArtistAutocompleteDialog> createState() =>
      _ArtistAutocompleteDialogState();
}

class _ArtistAutocompleteDialogState extends State<_ArtistAutocompleteDialog> {
  final TextEditingController _controller = TextEditingController();
  List<UserModel> _results = [];
  bool _isLoading = false;
  String _lastQuery = '';

  void _onChanged(String value) async {
    setState(() {
      _isLoading = true;
      _lastQuery = value;
    });
    final results = await widget.userService.searchUsers(value.trim());
    if (mounted && value == _lastQuery) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('artbeat_settings_search_for_artist'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter artist name'),
            onChanged: _onChanged,
          ),
          const SizedBox(height: 12),
          if (_isLoading) const CircularProgressIndicator(),
          if (!_isLoading && _results.isEmpty && _controller.text.isNotEmpty)
            Text('artbeat_settings_no_artists_found'.tr()),
          if (!_isLoading && _results.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final user = _results[index];
                  return ListTile(
                    leading:
                        ImageUrlValidator.isValidImageUrl(user.profileImageUrl)
                        ? CircleAvatar(
                            backgroundImage: ImageUrlValidator.safeNetworkImage(
                              user.profileImageUrl,
                            ),
                          )
                        : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user.fullName),
                    subtitle: Text('@${user.username}'),
                    onTap: () => Navigator.pop(context, user),
                  );
                },
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('common_cancel'.tr()),
        ),
      ],
    );
  }
}
