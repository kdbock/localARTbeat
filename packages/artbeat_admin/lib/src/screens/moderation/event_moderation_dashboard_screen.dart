import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/admin_event_model.dart';
import '../../services/admin_event_moderation_service.dart';

/// Admin screen for moderating events
/// Relocated to artbeat_admin for unified administration
class EventModerationDashboardScreen extends StatefulWidget {
  const EventModerationDashboardScreen({super.key});

  @override
  State<EventModerationDashboardScreen> createState() =>
      _EventModerationDashboardScreenState();
}

class _EventModerationDashboardScreenState
    extends State<EventModerationDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AdminEventModerationService _moderationService;

  late TabController _tabController;
  List<Map<String, dynamic>> _flaggedEvents = [];
  List<AdminEventModel> _pendingEvents = [];
  List<AdminEventModel> _approvedEvents = [];
  List<AdminEventModel> _allEvents = [];
  Map<String, dynamic>? _analytics;

  bool _isLoading = true;
  String? _errorMessage;
  final DateFormat _dateTimeFormat = DateFormat('EEE, MMM d • h:mm a');

  @override
  void initState() {
    super.initState();
    _moderationService = context.read<AdminEventModerationService>();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final futures = await Future.wait([
        _moderationService.getFlaggedEventsWithDetails(),
        _moderationService.getPendingEvents(),
        _moderationService.getApprovedEvents(),
        _moderationService.getModerationAnalytics(),
        _moderationService.getAllEvents(),
      ]);

      setState(() {
        _flaggedEvents = futures[0] as List<Map<String, dynamic>>;
        _pendingEvents = futures[1] as List<AdminEventModel>;
        _approvedEvents = futures[2] as List<AdminEventModel>;
        _analytics = futures[3] as Map<String, dynamic>;
        _allEvents = futures[4] as List<AdminEventModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('event_mod_title'.tr()),
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'event_mod_flagged_events'.tr()),
            Tab(text: 'event_mod_pending_review'.tr()),
            Tab(text: 'event_mod_approved_events'.tr()),
            const Tab(text: 'Manage'),
            Tab(text: 'event_mod_analytics'.tr()),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFlaggedEventsTab(),
                    _buildPendingEventsTab(),
                    _buildApprovedEventsTab(),
                    _buildManageEventsTab(),
                    _buildAnalyticsTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(_errorMessage ?? 'Error loading events',
              style: const TextStyle(color: Colors.white)),
          ElevatedButton(
              onPressed: _loadData, child: Text('common_retry'.tr())),
        ],
      ),
    );
  }

  Widget _buildFlaggedEventsTab() {
    if (_flaggedEvents.isEmpty)
      return const Center(
          child:
              Text('No flagged events', style: TextStyle(color: Colors.white)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _flaggedEvents.length,
      itemBuilder: (context, index) =>
          _buildFlaggedEventCard(_flaggedEvents[index]),
    );
  }

  Widget _buildFlaggedEventCard(Map<String, dynamic> data) {
    final event = data['event'] as AdminEventModel;
    final flag = data['flag'] as Map<String, dynamic>;
    final flagId = data['flagId'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Text('Reason: ${flag['reason']}',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _dismissFlag(flagId, event.id),
                child: const Text('Dismiss Flag',
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _deleteEvent(event.id),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete Event'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingEventsTab() {
    if (_pendingEvents.isEmpty)
      return const Center(
          child:
              Text('No pending events', style: TextStyle(color: Colors.white)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingEvents.length,
      itemBuilder: (context, index) =>
          _buildPendingEventCard(_pendingEvents[index]),
    );
  }

  Widget _buildPendingEventCard(AdminEventModel event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Text(event.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _reviewEvent(event.id, false),
                child: Text('common_reject'.tr(),
                    style: const TextStyle(color: Colors.redAccent)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _reviewEvent(event.id, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('common_approve'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedEventsTab() {
    if (_approvedEvents.isEmpty)
      return const Center(
          child: Text('No approved events',
              style: TextStyle(color: Colors.white)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _approvedEvents.length,
      itemBuilder: (context, index) =>
          _buildApprovedEventCard(_approvedEvents[index]),
    );
  }

  Widget _buildApprovedEventCard(AdminEventModel event) {
    return ListTile(
      title: Text(event.title, style: const TextStyle(color: Colors.white)),
      subtitle:
          Text(event.location, style: const TextStyle(color: Colors.white70)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        onPressed: () => _deleteEvent(event.id),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_analytics == null)
      return const Center(
          child:
              Text('No analytics data', style: TextStyle(color: Colors.white)));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatCard(
              'Total Reviews', _analytics!['totalReviews']?.toString() ?? '0'),
          const SizedBox(height: 12),
          _buildStatCard('Approval Rate',
              '${((_analytics!['approvalRate'] ?? 0) * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildManageEventsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showEventEditor(),
                icon: const Icon(Icons.add),
                label: const Text('Create Local Event'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _allEvents.isEmpty
              ? const Center(
                  child: Text('No events found',
                      style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _allEvents.length,
                  itemBuilder: (context, index) {
                    final event = _allEvents[index];
                    return Card(
                      color: Colors.white.withValues(alpha: 0.08),
                      child: ListTile(
                        title: Text(event.title,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          '${event.location} • ${_formatEventDateRange(event)} • ${event.isPublic ? "Public" : "Private"} • ${event.isActive ? "Active" : "Inactive"}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () => _showEventEditor(event: event),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteEvent(event.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatEventDateRange(AdminEventModel event) {
    final start = _dateTimeFormat.format(event.startDate.toLocal());
    if (event.endDate == null) return start;
    final end = _dateTimeFormat.format(event.endDate!.toLocal());
    return '$start → $end';
  }

  Future<void> _showEventEditor({AdminEventModel? event}) async {
    final titleController = TextEditingController(text: event?.title ?? '');
    final descriptionController =
        TextEditingController(text: event?.description ?? '');
    final locationController =
        TextEditingController(text: event?.location ?? '');
    final imageUrlController = TextEditingController();
    final imageUrls = List<String>.from(event?.imageUrls ?? <String>[]);
    DateTime startDate =
        event?.startDate ?? DateTime.now().add(const Duration(hours: 1));
    DateTime? endDate = event?.endDate;
    var isPublic = event?.isPublic ?? true;
    var isActive = event?.isActive ?? true;
    var isUploadingImage = false;

    final didSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(event == null ? 'Create Local Event' : 'Edit Event'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title')),
                  TextField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description')),
                  TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location')),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start date & time'),
                    subtitle: Text(startDate.toLocal().toString()),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (pickedDate == null) return;
                      if (!context.mounted) return;
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(startDate),
                      );
                      if (pickedTime == null) return;
                      if (!context.mounted) return;
                      setStateDialog(() {
                        startDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End date & time (optional)'),
                    subtitle: Text(
                      endDate == null
                          ? 'Not set'
                          : endDate!.toLocal().toString(),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (endDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setStateDialog(() => endDate = null),
                          ),
                        const Icon(Icons.calendar_month),
                      ],
                    ),
                    onTap: () async {
                      final base =
                          endDate ?? startDate.add(const Duration(hours: 2));
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: base,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (pickedDate == null) return;
                      if (!context.mounted) return;
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(base),
                      );
                      if (pickedTime == null) return;
                      if (!context.mounted) return;
                      setStateDialog(() {
                        endDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: imageUrlController,
                          decoration:
                              const InputDecoration(labelText: 'Photo URL'),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final url = imageUrlController.text.trim();
                          if (url.isEmpty) return;
                          setStateDialog(() {
                            imageUrls.add(url);
                            imageUrlController.clear();
                          });
                        },
                        icon: const Icon(Icons.add_photo_alternate),
                      ),
                      IconButton(
                        tooltip: 'Upload image',
                        onPressed: isUploadingImage
                            ? null
                            : () async {
                                try {
                                  setStateDialog(() => isUploadingImage = true);
                                  Uint8List? bytes;
                                  String fileName = 'image.jpg';
                                  if (Platform.isMacOS ||
                                      Platform.isWindows ||
                                      Platform.isLinux) {
                                    final result =
                                        await FilePicker.platform.pickFiles(
                                      type: FileType.image,
                                      withData: true,
                                    );
                                    if (result == null || result.files.isEmpty)
                                      return;
                                    final file = result.files.first;
                                    bytes = file.bytes;
                                    fileName = file.name;
                                    if (bytes == null && file.path != null) {
                                      bytes =
                                          await File(file.path!).readAsBytes();
                                    }
                                    if (bytes == null) {
                                      throw Exception(
                                          'Failed to read selected image file');
                                    }
                                  } else {
                                    final picker = ImagePicker();
                                    final picked = await picker.pickImage(
                                      source: ImageSource.gallery,
                                    );
                                    if (picked == null) return;
                                    bytes = await picked.readAsBytes();
                                    fileName = picked.name;
                                  }

                                  final uid =
                                      FirebaseAuth.instance.currentUser?.uid;
                                  if (uid == null || uid.isEmpty) {
                                    throw Exception('Not signed in');
                                  }
                                  final objectPath =
                                      'events/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';
                                  final ref = FirebaseStorage.instance
                                      .ref()
                                      .child(objectPath);
                                  await ref.putData(bytes);
                                  final downloadUrl =
                                      await ref.getDownloadURL();

                                  setStateDialog(() {
                                    imageUrls.add(downloadUrl);
                                  });
                                } on FirebaseException catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Image upload failed: ${e.code} ${e.message ?? ''}',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Image upload failed: $e')),
                                    );
                                  }
                                } finally {
                                  setStateDialog(
                                      () => isUploadingImage = false);
                                }
                              },
                        icon: isUploadingImage
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_file),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < imageUrls.length; i++)
                    ListTile(
                      dense: true,
                      title: Text(imageUrls[i],
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon:
                            const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => setStateDialog(() {
                          imageUrls.removeAt(i);
                        }),
                      ),
                    ),
                  SwitchListTile(
                    value: isPublic,
                    onChanged: (v) => setStateDialog(() => isPublic = v),
                    title: const Text('Public'),
                  ),
                  SwitchListTile(
                    value: isActive,
                    onChanged: (v) => setStateDialog(() => isActive = v),
                    title: const Text('Active'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                if (event == null) {
                  await _moderationService.createLocalEvent(
                    title: titleController.text,
                    description: descriptionController.text,
                    location: locationController.text,
                    imageUrls: imageUrls,
                    startDate: startDate,
                    endDate: endDate,
                    isPublic: isPublic,
                    isActive: isActive,
                  );
                } else {
                  await _moderationService.updateLocalEvent(
                    eventId: event.id,
                    title: titleController.text,
                    description: descriptionController.text,
                    location: locationController.text,
                    imageUrls: imageUrls,
                    startDate: startDate,
                    endDate: endDate,
                    isPublic: isPublic,
                    isActive: isActive,
                  );
                }
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (didSave == true) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(event == null ? 'Event created' : 'Event updated')),
        );
      }
    }
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _reviewEvent(String eventId, bool approve) async {
    try {
      await _moderationService.reviewEvent(eventId, approve);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error reviewing event: $e')));
      }
    }
  }

  Future<void> _dismissFlag(String flagId, String eventId) async {
    try {
      await _moderationService.dismissFlag(flagId, eventId);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error dismissing flag: $e')));
      }
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('common_cancel'.tr())),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('common_delete'.tr(),
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _moderationService.deleteEvent(eventId);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting event: $e')));
        }
      }
    }
  }
}
