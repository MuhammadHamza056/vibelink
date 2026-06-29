import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/toast_util.dart';
import '../../../shared/widgets/badge_chip.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/profile_provider.dart';

/// Opens the bottom sheet that edits username, avatar photo and vibe tags, then
/// persists everything in one PATCH /api/profile via [ProfileNotifier].
void showEditProfileSheet(
  BuildContext context,
  WidgetRef ref,
  dynamic user,
  List<String> availableTags,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => EditProfileSheet(user: user, availableTags: availableTags),
  );
}

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({
    super.key,
    required this.user,
    required this.availableTags,
  });

  final dynamic user;
  final List<String> availableTags;

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final TextEditingController _usernameCtrl;
  late final String _existingAvatarUrl;

  late final _form =
      editProfileFormProvider(widget.user.vibeTags as List<String>);

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.user.username as String);
    _existingAvatarUrl = widget.user.avatarUrl as String;
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final result = await ref.read(_form.notifier).pickImage(source);
    if (!mounted) return;
    if (result == PickPhotoResult.failed) {
      ToastUtil.error(context, 'Could not access the photo. Check permissions.');
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.primaryLight),
              title: Text('Take Photo', style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primaryLight),
              title:
                  Text('Choose from Gallery', style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            if (ref.read(_form).pickedImagePath != null ||
                _existingAvatarUrl.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                title: Text('Remove Photo',
                    style: AppTextStyles.bodyLarge
                        .copyWith(color: AppColors.error)),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  ref.read(_form.notifier).setImage(null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      ToastUtil.warning(context, 'Username can\'t be empty.');
      return;
    }

    final form = ref.read(_form);
    final ok = await ref.read(profileProvider.notifier).updateProfile(
          username: username,
          avatarFilePath: form.pickedImagePath,
          vibeTags: form.selectedTags.toList(),
        );

    if (!mounted) return;
    if (ok) {
      ToastUtil.success(context, 'Profile updated ✨');
      Navigator.of(context).pop();
    } else {
      final error = ref.read(profileProvider).error ?? 'Update failed.';
      ToastUtil.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-read so the Save button reflects the in-flight save state.
    final isSaving = ref.watch(profileProvider).isSaving;
    final form = ref.watch(_form);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Edit Profile', style: AppTextStyles.titleLarge),
            const SizedBox(height: 20),
            Center(
                child: _AvatarPicker(
              pickedPath: form.pickedImagePath,
              avatarUrl: _existingAvatarUrl,
              username: _usernameCtrl.text,
              onTap: _showPhotoSourceSheet,
            )),
            const SizedBox(height: 20),
            Text('Username', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            _SheetField(controller: _usernameCtrl, hint: 'Your username'),
            const SizedBox(height: 20),
            Text('My Vibes', style: AppTextStyles.labelLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.availableTags.map((tag) {
                final isSelected = form.selectedTags.contains(tag);
                return VibeTagChip(
                  label: tag,
                  isSelected: isSelected,
                  onTap: () => ref.read(_form.notifier).toggleTag(tag),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: 'Save Changes',
              isLoading: isSaving,
              onTap: isSaving ? null : _save,
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.pickedPath,
    required this.avatarUrl,
    required this.username,
    required this.onTap,
  });

  final String? pickedPath;
  final String avatarUrl;
  final String username;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Center(
          child: username.trim().isEmpty
              ? const Icon(Icons.person_rounded,
                  color: AppColors.textSecondary, size: 40)
              : Text(
                  username.trim()[0].toUpperCase(),
                  style: AppTextStyles.displayMedium
                      .copyWith(color: AppColors.primaryLight),
                ),
        );

    Widget image;
    if (pickedPath != null) {
      image = Image.file(File(pickedPath!), fit: BoxFit.cover);
    } else if (avatarUrl.isNotEmpty) {
      image = CachedNetworkImage(
        imageUrl: ApiEndpoints.mediaUrl(avatarUrl),
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback(),
        errorWidget: (_, __, ___) => fallback(),
      );
    } else {
      image = fallback();
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardBg,
              border: Border.all(color: AppColors.cardBorder, width: 2),
            ),
            child: ClipOval(child: image),
          ),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 2),
            ),
            child: const Icon(Icons.camera_alt_rounded,
                color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
