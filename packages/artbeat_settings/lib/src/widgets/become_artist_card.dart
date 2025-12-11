import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';
import '../routes.dart';

class BecomeArtistCard extends StatelessWidget {
  final UserModel user;

  const BecomeArtistCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Don't show for users who are already artists
    if (user.userType != UserType.regular) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'artbeat_settings_join_as_artist'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'artbeat_settings_artist_description'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    SettingsRoutes.becomeArtist,
                    arguments: user,
                  );
                },
                child: Text('artbeat_settings_become_artist_button'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
