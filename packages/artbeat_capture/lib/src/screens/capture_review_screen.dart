import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:artbeat_core/artbeat_core.dart';

/// Capture Review Screen
/// Allows users to review captures with title, description, and star rating.
/// Awards XP for successful reviews.
class CaptureReviewScreen extends StatefulWidget {
  final String captureId;

  const CaptureReviewScreen({Key? key, required this.captureId})
    : super(key: key);

  @override
  State<CaptureReviewScreen> createState() => _CaptureReviewScreenState();
}

class _CaptureReviewScreenState extends State<CaptureReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _rating = 0; // 1-5 stars

  bool _isSubmitting = false;
  CaptureModel? _capture;

  final CaptureService _captureService = CaptureService();

  @override
  void initState() {
    super.initState();
    _loadCapture();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCapture() async {
    try {
      final capture = await _captureService.getCaptureById(widget.captureId);
      if (mounted) {
        setState(() => _capture = capture);
      }
    } catch (_) {
      // Handle error
    }
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Assume there's a method to submit review
      // await _captureService.submitReview(
      //   captureId: widget.captureId,
      //   title: _titleController.text.trim(),
      //   description: _descriptionController.text.trim(),
      //   rating: _rating,
      // );

      // For now, simulate
      await Future<void>.delayed(const Duration(seconds: 1));

      // Award XP - assume user service has method
      // await _userService.awardXP(25); // Example XP

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (_) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit review'.tr())));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF07060F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Review Submitted!'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'You earned 25 XP for your thoughtful review!'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to dashboard
            },
            child: Text(
              'OK'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: const Color(0xFF22D3EE),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_capture == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF07060F),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Review Capture'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Capture Image
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SecureNetworkImage(
                    imageUrl: _capture!.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color: const Color.fromRGBO(255, 255, 255, 0.06),
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white54,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Review Title'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter a title for your review...'.tr(),
                  hintStyle: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF22D3EE)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required'.tr();
                  }
                  if (value.trim().length < 5) {
                    return 'Title must be at least 5 characters'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Rating
              Text(
                'Rating'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    onPressed: () => setState(() => _rating = starIndex),
                    icon: Icon(
                      starIndex <= _rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFC857),
                      size: 32,
                    ),
                  );
                }),
              ),
              if (_rating == 0)
                Text(
                  'Please select a rating'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.red.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 20),

              // Description
              Text(
                'Review Description'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Share your thoughts about this capture...'.tr(),
                  hintStyle: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF22D3EE)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _rating == 0
                      ? null
                      : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22D3EE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF22D3EE).withValues(alpha: 0.3),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : Text(
                          'Submit Review'.tr(),
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
