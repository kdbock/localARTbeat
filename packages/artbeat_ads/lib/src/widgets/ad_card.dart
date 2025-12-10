import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/index.dart';

class AdCard extends StatelessWidget {
  final LocalAd ad;
  final VoidCallback? onDelete;

  const AdCard({
    Key? key,
    required this.ad,
    this.onDelete,
  }) : super(key: key);

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
          if (ad.imageUrl != null && ad.imageUrl!.isNotEmpty && (ad.imageUrl!.startsWith('http://') || ad.imageUrl!.startsWith('https://')))
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: ad.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
