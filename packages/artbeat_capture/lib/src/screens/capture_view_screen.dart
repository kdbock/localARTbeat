import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show AppLogger, CaptureStatus, CaptureModel, UploadSafetyService;
import 'package:provider/provider.dart';

class CaptureViewScreen extends StatefulWidget {
  final File imageFile;
  final String title;
  final String artistName;
  final String description;

  const CaptureViewScreen({
    super.key,
    required this.imageFile,
    required this.title,
    required this.artistName,
    required this.description,
  });

  @override
  State<CaptureViewScreen> createState() => _CaptureViewScreenState();
}

class _CaptureViewScreenState extends State<CaptureViewScreen> {
  bool _isSubmitting = false;
  bool _isPostingArtFlex = false;
  final ImagePicker _imagePicker = ImagePicker();
  final UploadSafetyService _uploadSafetyService = UploadSafetyService();

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      final captureService = context.read<CaptureService>();

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get current location
      Position? position;
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          final permission = await Geolocator.checkPermission();
          if (permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever) {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        AppLogger.warning('Could not get location for capture: $e');
      }

      // Upload image
      final capture = CaptureModel(
        id: '',
        userId: user.uid,
        imageUrl: '',
        createdAt: DateTime.now(),
        title: widget.title.trim(),
        artistName: widget.artistName.trim().isNotEmpty
            ? widget.artistName.trim()
            : null,
        description: widget.description.trim().isNotEmpty
            ? widget.description.trim()
            : null,
        location: position != null
            ? GeoPoint(position.latitude, position.longitude)
            : null,
        isPublic: true,
        status: CaptureStatus.approved,
      );

      final outcome = await captureService.createCaptureFromLocalImage(
        capture: capture,
        localImagePath: widget.imageFile.path,
      );

      if (mounted) {
        final message = outcome.queuedOffline
            ? 'Capture saved to the offline queue. It will upload automatically when connection improves.'
            : 'capture_upload_success'.tr();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));

        if (!outcome.queuedOffline && outcome.captureId != null) {
          await _promptArtFlexShot(outcome.captureId!);
          if (!mounted) return;
        }

        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      AppLogger.error('Error submitting capture: $e');
      if (mounted) {
        final message = kDebugMode
            ? 'Failed to submit capture: $e'
            : 'capture_upload_error_generic'.tr();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _promptArtFlexShot(String captureId) async {
    final shouldTakeArtFlex = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Drop an ARTflex Shot?'),
        content: const Text(
          'Take a selfie with this artwork and auto-share it to the community feed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ARTflex Shot'),
          ),
        ],
      ),
    );

    if (shouldTakeArtFlex == true) {
      await _captureAndPostArtFlex(captureId);
    }
  }

  Future<void> _captureAndPostArtFlex(String captureId) async {
    if (_isPostingArtFlex) return;

    setState(() => _isPostingArtFlex = true);
    try {
      final captureService = context.read<CaptureService>();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final selfie = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1400,
      );

      if (selfie == null) {
        return;
      }

      final selfieFile = File(selfie.path);
      final moderationDecision = await _uploadSafetyService.scanImageFile(
        imageFile: selfieFile,
        source: 'capture_artflex_selfie_upload',
        userId: user.uid,
        metadata: {'captureId': captureId},
      );
      if (!moderationDecision.isAllowed) {
        throw Exception(moderationDecision.reason);
      }

      final bytes = await selfie.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final selfiePath = 'community/artflex/${user.uid}_$timestamp.jpg';

      final selfieRef = FirebaseStorage.instance.ref().child(selfiePath);
      await selfieRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final selfieUrl = await selfieRef.getDownloadURL();

      String? captureImageUrl;
      try {
        final createdCapture = await captureService.getCaptureById(captureId);
        captureImageUrl = createdCapture?.imageUrl;
      } catch (_) {
        // Keep selfie post even if capture lookup fails.
      }

      await FirebaseFirestore.instance.collection('socialActivities').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous Explorer',
        'userAvatar': user.photoURL,
        'type': 'capture',
        'message':
            '${user.displayName ?? 'Someone'} dropped an ARTflex with "${widget.title.trim().isNotEmpty ? widget.title.trim() : 'Untitled'}"',
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': {
          'source': 'artflex_capture_selfie',
          'captureId': captureId,
          'artTitle': widget.title.trim().isNotEmpty
              ? widget.title.trim()
              : 'Untitled',
          'selfieUrl': selfieUrl,
          'photoUrl': selfieUrl,
          'artPhotoUrl': captureImageUrl,
        },
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ARTflex posted to the community feed!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not post ARTflex shot: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPostingArtFlex = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          // BACKGROUND GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF07060F),
                  Color(0xFF0B1222),
                  Color(0xFF0A1B15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                HudTopBar(
                  title: 'capture_view_title'.tr(),
                  subtitle: 'capture_view_subtitle'.tr(),
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: GlassCard(
                          radius: 26,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // IMAGE PREVIEW
                              ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.file(
                                  widget.imageFile,
                                  width: double.infinity,
                                  height: 240,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              const SizedBox(height: 18),

                              // TITLE
                              Text(
                                widget.title,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white.withAlpha(
                                    (0.95 * 255).toInt(),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 6),

                              if (widget.artistName.trim().isNotEmpty) ...[
                                Text(
                                  widget.artistName.trim(),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withAlpha(
                                      (0.82 * 255).toInt(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],

                              // DESCRIPTION
                              if (widget.description.trim().isNotEmpty)
                                Text(
                                  widget.description,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withAlpha(
                                      (0.7 * 255).toInt(),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 24),

                              // ACTION BUTTONS
                              Row(
                                children: [
                                  Expanded(
                                    child: HudButton(
                                      label: 'capture_view_edit'.tr(),
                                      icon: Icons.edit_rounded,
                                      onTap: _isSubmitting
                                          ? () {}
                                          : () => Navigator.pop(context),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: HudButton(
                                      label: _isSubmitting
                                          ? 'capture_upload_submitting'.tr()
                                          : 'capture_view_submit'.tr(),
                                      icon: Icons.cloud_upload_rounded,
                                      onTap: _isSubmitting ? () {} : _submit,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
