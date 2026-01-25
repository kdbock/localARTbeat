import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/index.dart';
import 'ad_image_rotator.dart';
import 'package:easy_localization/easy_localization.dart';

class AdCard extends StatelessWidget {
  final LocalAd ad;
  final VoidCallback? onDelete;

  const AdCard({Key? key, required this.ad, this.onDelete}) : super(key: key);

  void _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _launchPhone(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _launchEmail(String email) async {
    final url = 'mailto:$email';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdImage(ad),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ad.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Chip(
                      label: Text('${ad.daysRemaining}d'),
                      backgroundColor: Colors.blue[100],
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ad.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    if (ad.contactInfo != null)
                      _ContactButton(
                        icon: Icons.phone,
                        label: 'Call',
                        onTap: () => _launchPhone(ad.contactInfo!),
                      ),
                    if (ad.contactInfo != null && ad.contactInfo!.contains('@'))
                      _ContactButton(
                        icon: Icons.email,
                        label: 'Email',
                        onTap: () => _launchEmail(ad.contactInfo!),
                      ),
                    if (ad.websiteUrl != null)
                      _ContactButton(
                        icon: Icons.link,
                        label: 'Visit',
                        onTap: () => _launchUrl(ad.websiteUrl!),
                      ),
                    if (onDelete != null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete, size: 16),
                        label: Text('ads_ad_card_text_delete'.tr()),
                        onPressed: onDelete,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdImage(LocalAd ad) {
    final images = (ad.imageUrls ?? [])
        .where((url) => url.isNotEmpty)
        .toList();
    if (images.isEmpty && ad.imageUrl != null && ad.imageUrl!.isNotEmpty) {
      images.add(ad.imageUrl!);
    }
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }
    return AdImageRotator(
      imageUrls: images,
      width: double.infinity,
      height: 180,
      fit: BoxFit.cover,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
