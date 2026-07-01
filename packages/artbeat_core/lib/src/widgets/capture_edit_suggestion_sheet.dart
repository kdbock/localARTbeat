import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/capture_model.dart';
import '../services/capture_edit_suggestion_service.dart';
import '../theme/artbeat_colors.dart';

class CaptureEditSuggestionSheet extends StatefulWidget {
  const CaptureEditSuggestionSheet({
    super.key,
    required this.capture,
    this.service,
  });

  final CaptureModel capture;
  final CaptureEditSuggestionService? service;

  @override
  State<CaptureEditSuggestionSheet> createState() =>
      _CaptureEditSuggestionSheetState();
}

class _CaptureEditSuggestionSheetState
    extends State<CaptureEditSuggestionSheet> {
  late final CaptureEditSuggestionService _service;
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _categoryController;
  late final TextEditingController _noteController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? CaptureEditSuggestionService();
    _titleController = TextEditingController(text: widget.capture.title ?? '');
    _artistController = TextEditingController(
      text: widget.capture.artistName ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.capture.description ?? '',
    );
    _locationController = TextEditingController(
      text: widget.capture.locationName ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.capture.artType ?? '',
    );
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _service.submitSuggestion(
        capture: widget.capture,
        suggestedTitle: _titleController.text,
        suggestedArtistName: _artistController.text,
        suggestedDescription: _descriptionController.text,
        suggestedLocationName: _locationController.text,
        suggestedArtType: _categoryController.text,
        note: _noteController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_messageForError(error)),
          backgroundColor: const Color(0xFFFF3D8D),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _messageForError(Object error) {
    final text = error.toString();
    if (text.contains('Sign in')) {
      return 'Please sign in before suggesting an edit.';
    }
    if (text.contains('correction') || text.contains('note')) {
      return 'Change a detail or add a note before submitting.';
    }
    return 'Could not submit that edit suggestion. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF090A12),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Suggest an edit',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Corrections are reviewed before they appear publicly.',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _field(_titleController, 'Title'),
                _field(_artistController, 'Artist'),
                _field(_descriptionController, 'Description', maxLines: 3),
                _field(_locationController, 'Location note'),
                _field(_categoryController, 'Category'),
                _field(
                  _noteController,
                  'Moderator note',
                  hint: 'What should we know about this correction?',
                  maxLines: 3,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: ArtbeatColors.secondaryTeal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withValues(
                        alpha: 0.12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.fact_check_outlined),
                    label: Text(
                      _isSubmitting ? 'Submitting' : 'Submit for review',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.68)),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.42)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          border: _border(Colors.white.withValues(alpha: 0.12)),
          enabledBorder: _border(Colors.white.withValues(alpha: 0.12)),
          focusedBorder: _border(ArtbeatColors.secondaryTeal),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color),
    );
  }
}
