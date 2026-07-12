import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/toast_util.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/memories_provider.dart';

/// Bottom-sheet form for creating a memory (POST /api/memories).
///
/// Open it with [AddMemorySheet.show]; it manages its own submitting state and
/// closes itself on success after showing a toast.
class AddMemorySheet extends ConsumerStatefulWidget {
  const AddMemorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMemorySheet(),
    );
  }

  @override
  ConsumerState<AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends ConsumerState<AddMemorySheet> {
  final _titleCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();
  final _selectedTags = <String>{};
  final _picker = ImagePicker();
  String? _imagePath;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (file == null) return;
      setState(() => _imagePath = file.path);
    } catch (_) {
      if (mounted) {
        ToastUtil.error(context, 'Could not access the photo. Check permissions.');
      }
    }
  }

  void _showImageSourceSheet() {
    FocusScope.of(context).unfocus();
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
                  color: AppColors.gold),
              title: Text('Take Photo', style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.gold),
              title:
                  Text('Choose from Gallery', style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                title: Text('Remove Photo',
                    style: AppTextStyles.bodyLarge
                        .copyWith(color: AppColors.error)),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  setState(() => _imagePath = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_titleCtrl.text.trim().isEmpty) {
      ToastUtil.warning(context, 'Give your memory a title');
      return;
    }
    if (_captionCtrl.text.trim().isEmpty) {
      ToastUtil.warning(context, 'Add a caption to remember the moment');
      return;
    }

    setState(() => _submitting = true);
    final ok = await ref.read(memoriesProvider.notifier).createMemory(
          title: _titleCtrl.text.trim(),
          caption: _captionCtrl.text.trim(),
          imageFilePath: _imagePath,
          vibeTags: _selectedTags.toList(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).pop();
      ToastUtil.success(context, 'Memory saved ✨');
    } else {
      final err = ref.read(memoriesProvider).error;
      ToastUtil.error(context, err ?? 'Could not save your memory');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Padding keeps the form above the keyboard when it opens.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grab handle
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                  child: Text(
                    '💭 New Memory',
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Capture a moment worth keeping',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 24),

                // Photo picker
                _PhotoPicker(
                  imagePath: _imagePath,
                  onTap: _showImageSourceSheet,
                ),
                const SizedBox(height: 18),

                _Field(
                  controller: _titleCtrl,
                  label: 'Title',
                  hint: 'Sunset picnic with new friends',
                  icon: Icons.title_rounded,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _captionCtrl,
                  label: 'Caption',
                  hint: 'We met at the park challenge and stayed till dark.',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                Text('Vibe tags', style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.vibeTags.map((tag) {
                    final selected = _selectedTags.contains(tag);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: selected ? AppColors.goldGradient : null,
                          color: selected ? null : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : AppColors.cardBorder,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                GradientButton(
                  label: 'Save Memory',
                  gradient: AppColors.goldGradient,
                  onTap: _submitting ? null : _submit,
                  isLoading: _submitting,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tappable photo area — shows a preview of the picked image or a prompt to
/// add one from the camera/gallery.
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.imagePath, required this.onTap});

  final String? imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: imagePath == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_rounded,
                      color: AppColors.gold, size: 32),
                  const SizedBox(height: 10),
                  Text('Add a photo', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 4),
                  Text('Camera or gallery', style: AppTextStyles.bodySmall),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(imagePath!), fit: BoxFit.cover),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            'Change',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Labelled glass text field used throughout the sheet.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textInputAction: textInputAction,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint),
            prefixIcon: maxLines == 1
                ? Icon(icon, color: AppColors.textSecondary, size: 20)
                : null,
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
              borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
