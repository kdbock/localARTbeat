import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Modern Unified Admin Upload Tools Screen
/// Consolidates all administrative data upload utilities into one modern interface.
class ModernUnifiedAdminUploadToolsScreen extends StatefulWidget {
  const ModernUnifiedAdminUploadToolsScreen({super.key});

  @override
  State<ModernUnifiedAdminUploadToolsScreen> createState() =>
      _ModernUnifiedAdminUploadToolsScreenState();
}

class _ModernUnifiedAdminUploadToolsScreenState
    extends State<ModernUnifiedAdminUploadToolsScreen> {
  final Map<String, String> _uploadTypes = {
    'Artist Profiles': 'artistProfiles',
    'Gallery': 'business',
    'Admin Ads': 'admin_ads',
    'User Ads': 'user_ads',
    'Artist Ads': 'artist_ads',
    'Gallery Ads': 'gallery_ads',
    'Events': 'event',
    'Users': 'user',
    'Artworks': 'artworks',
    'Captures': 'captures',
  };

  String _selectedLabel = 'Artist Profiles';
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = _uploadTypes[_selectedLabel]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EnhancedUniversalHeader(
        title: 'Admin Upload Tools',
        showBackButton: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTypeSelector(),
                const SizedBox(height: 24),
                Expanded(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: ModernAdminUploadForm(
                      label: 'Upload $_selectedLabel',
                      hint: 'Enter $_selectedLabel data (JSON, ID, etc)',
                      uploadType: _selectedType,
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

  Widget _buildTypeSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedLabel,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down_circle,
                color: Color(0xFF8C52FF)),
            items: _uploadTypes.keys.map((String label) {
              return DropdownMenuItem<String>(
                value: label,
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedLabel = newValue;
                  _selectedType = _uploadTypes[newValue]!;
                });
              }
            },
          ),
        ),
      ),
    );
  }
}

class ModernAdminUploadForm extends StatefulWidget {
  final String label;
  final String hint;
  final String uploadType;

  const ModernAdminUploadForm({
    super.key,
    required this.label,
    required this.hint,
    required this.uploadType,
  });

  @override
  State<ModernAdminUploadForm> createState() => _ModernAdminUploadFormState();
}

class _ModernAdminUploadFormState extends State<ModernAdminUploadForm> {
  final TextEditingController _controller = TextEditingController();
  String? _result;
  bool _loading = false;

  void _upload() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter data to upload')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
    });

    // Simulate upload delay
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _loading = false;
        _result = 'Successfully uploaded to \'${widget.uploadType}\'';
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF764ba2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type: ${widget.uploadType}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                labelText: widget.hint,
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              minLines: 10,
              maxLines: null,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _upload,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8C52FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Execute Upload',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _result!,
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
