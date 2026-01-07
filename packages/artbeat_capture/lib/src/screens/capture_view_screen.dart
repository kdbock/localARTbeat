import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger, CaptureStatus, CaptureModel;

class CaptureViewScreen extends StatefulWidget {
  final File imageFile;
  final String title;
  final String description;

  const CaptureViewScreen({
    super.key,
    required this.imageFile,
    required this.title,
    required this.description,
  });

  @override
  State<CaptureViewScreen> createState() => _CaptureViewScreenState();
}

class _CaptureViewScreenState extends State<CaptureViewScreen> {
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
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
          if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
              ),
            );
          }
        }
      } catch (e) {
        AppLogger.warning('Could not get location for capture: $e');
      }

      // Upload image
      final storageService = StorageService();
      final imageUrl = await storageService.uploadCaptureImage(
        widget.imageFile,
        user.uid,
      );

      // Create capture model
      final capture = CaptureModel(
        id: '', 
        userId: user.uid,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        title: widget.title.trim(),
        description: widget.description.trim().isNotEmpty
            ? widget.description.trim()
            : null,
        location: position != null
            ? GeoPoint(position.latitude, position.longitude)
            : null,
        isPublic: true,
        status: CaptureStatus.approved,
      );

      // Save to Firestore
      final captureService = CaptureService();
      await captureService.createCapture(capture);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('capture_upload_success'.tr())),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      AppLogger.error('Error submitting capture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('capture_upload_error_generic'.tr())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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

                              // DESCRIPTION
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
                                      onTap: _isSubmitting ? () {} : () => Navigator.pop(context),
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
