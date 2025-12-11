import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_capture/artbeat_capture.dart';

/// Screen that displays the current user's art captures
class MyCapturesScreen extends StatefulWidget {
  const MyCapturesScreen({super.key});

  @override
  State<MyCapturesScreen> createState() => _MyCapturesScreenState();
}

class _MyCapturesScreenState extends State<MyCapturesScreen> {
  final CaptureService _captureService = CaptureService();
  List<CaptureModel> _myCaptures = [];
  List<CaptureModel> _filteredCaptures = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMyCaptures();
  }

  Future<void> _loadMyCaptures() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final captures = await _captureService.getCapturesForUser(user.uid);
        if (mounted) {
          setState(() {
            _myCaptures = captures;
            _filteredCaptures = captures;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'capture_my_captures_user_not_authenticated'.tr();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'capture_my_captures_error_loading'.tr().replaceAll('{error}', e.toString());
          _isLoading = false;
        });
      }
    }
  }

  void _filterCaptures(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredCaptures = _myCaptures;
      } else {
        _filteredCaptures = _myCaptures.where((capture) {
          final title = (capture.title ?? 'Untitled').toLowerCase();
          final location = (capture.locationName ?? '').toLowerCase();
          final status = capture.status.value.toLowerCase();

          return title.contains(_searchQuery) ||
              location.contains(_searchQuery) ||
              status.contains(_searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex:
          -1, // Not part of main navigation, accessed from profile menu
      child: Scaffold(
        appBar: core.EnhancedUniversalHeader(
          title: 'My Captures',
          showLogo: false,
          showBackButton: true,
          showSearch: true,
          onSearchPressed: (query) {
            _filterCaptures(query);
          },
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadMyCaptures,
              tooltip: 'Refresh captures',
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () {
                Navigator.pushNamed(context, '/capture/camera');
              },
              tooltip: 'Take new capture',
            ),
          ],
          // Use app theme colors instead of custom gradient
          backgroundColor: core.ArtbeatColors.primaryPurple,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    core.ArtbeatColors.primaryPurple,
                  ),
                ),
              )
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadMyCaptures,
                      child: Text('admin_admin_settings_text_retry'.tr()),
                    ),
                  ],
                ),
              )
            : _myCaptures.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'capture_my_captures_no_captures_yet'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'capture_my_captures_start_capturing_description'.tr(),
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera),
                      label: Text('capture_my_captures_text_take_photo'.tr()),
                      onPressed: () {
                        Navigator.pushNamed(context, '/capture/camera');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: core.ArtbeatColors.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            : _filteredCaptures.isEmpty && _searchQuery.isNotEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'capture_my_captures_no_search_results'.tr().replaceAll('{query}', _searchQuery),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'capture_my_captures_try_different_search'.tr(),
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: core.ArtbeatColors.primaryPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _filteredCaptures = _myCaptures;
                        });
                      },
                      child: Text('capture_my_captures_hint_clear_search'.tr()),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadMyCaptures,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredCaptures.length,
                  itemBuilder: (context, index) {
                    final capture = _filteredCaptures[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: SizedBox(
                          width: 60,
                          height: 60,
                          child: core.SecureNetworkImage(
                            imageUrl: capture.imageUrl,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(8),
                            errorWidget: Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          capture.title ?? 'capture_my_captures_untitled'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (capture.locationName != null)
                              Text(
                                capture.locationName!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            Text(
                              'capture_my_captures_status'.tr().replaceAll('{status}', capture.status.value),
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    capture.status ==
                                        core.CaptureStatus.approved
                                    ? Colors.green
                                    : capture.status ==
                                          core.CaptureStatus.pending
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          capture.status == core.CaptureStatus.approved
                              ? Icons.check_circle
                              : capture.status == core.CaptureStatus.pending
                              ? Icons.pending
                              : Icons.error,
                          color: capture.status == core.CaptureStatus.approved
                              ? Colors.green
                              : capture.status == core.CaptureStatus.pending
                              ? Colors.orange
                              : Colors.red,
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/capture/detail',
                            arguments: {'captureId': capture.id},
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
