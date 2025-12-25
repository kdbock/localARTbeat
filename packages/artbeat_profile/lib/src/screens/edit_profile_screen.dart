import 'dart:io';
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';

import '../widgets/avatar_picker.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_multiline_text_field.dart';
import '../widgets/world_background.dart';
import '../widgets/glass_card.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;

  const EditProfileScreen({super.key, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final UserService _userService = UserService();

  bool _isLoading = true;
  bool _isSaving = false;

  String _displayName = '';
  String _handle = '';
  String _bio = '';
  String? _avatarUrl;

  File? _newAvatarFile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _userService.getUserProfile(widget.userId);

      if (!mounted) return;

      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_edit_error_loading'.tr())),
        );
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _displayName = (profile['fullName'] as String?) ?? '';
        _handle = (profile['username'] as String?) ?? '';
        _bio = (profile['bio'] as String?) ?? '';
        _avatarUrl = profile['profileImageUrl'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'profile_edit_error_loading'.tr(namedArgs: {'error': e.toString()}),
          ),
        ),
      );

      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    try {
      // Upload avatar if new one selected
      if (_newAvatarFile != null) {
        await _userService.uploadAndUpdateProfilePhoto(_newAvatarFile!);
      }

      // Update profile fields
      await _userService.updateUserProfileWithMap({
        'fullName': _displayName,
        'username': _handle,
        'bio': _bio,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('profile_edit_saved'.tr())));

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'profile_edit_save_error'.tr(namedArgs: {'error': e.toString()}),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: EnhancedUniversalHeader(
          title: 'profile_edit_title'.tr(),
          showBackButton: true,
          showLogo: false,
          showSearch: false,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: ArtbeatColors.primaryPurple,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        /// Avatar
                        AvatarPicker(
                          imageUrl: _avatarUrl,
                          onImageSelected: (file) {
                            _newAvatarFile = file;
                          },
                        ),

                        const SizedBox(height: 24),

                        /// Name
                        CustomTextField(
                          label: 'profile_display_name'.tr(),
                          initialValue: _displayName,
                          onSaved: (v) => _displayName = v ?? '',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'profile_required'.tr()
                              : null,
                        ),

                        const SizedBox(height: 16),

                        /// Handle
                        CustomTextField(
                          label: 'profile_username'.tr(),
                          prefixText: '@',
                          initialValue: _handle,
                          onSaved: (v) => _handle = v?.trim() ?? '',
                        ),

                        const SizedBox(height: 16),

                        /// Bio
                        CustomMultilineTextField(
                          label: 'profile_bio'.tr(),
                          initialValue: _bio,
                          maxLines: 5,
                          onSaved: (v) => _bio = v ?? '',
                        ),

                        const SizedBox(height: 24),

                        /// Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ArtbeatColors.primaryPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text('profile_save_changes'.tr()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
