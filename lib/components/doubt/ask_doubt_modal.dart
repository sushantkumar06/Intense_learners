import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/api_client.dart';
import '../../services/upload_service.dart';
import '../../theme/app_theme.dart';
import '../ui/ui.dart';

class AskDoubtModal extends ConsumerStatefulWidget {
  final bool visible;
  final VoidCallback onClose;
  final VoidCallback onSuccess;

  const AskDoubtModal({
    super.key,
    required this.visible,
    required this.onClose,
    required this.onSuccess,
  });

  @override
  ConsumerState<AskDoubtModal> createState() => _AskDoubtModalState();
}

class _AskDoubtModalState extends ConsumerState<AskDoubtModal> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _subjectCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  String _priority = "normal";

  UploadedFile? _image;
  UploadedFile? _pdf;
  bool _uploadingImage = false;
  bool _uploadingPdf = false;
  bool _submitting = false;

  final _priorities = [
    {'value': 'low', 'label': 'Low', 'bg': AppColors.mintTint, 'text': AppColors.mint},
    {'value': 'normal', 'label': 'Normal', 'bg': AppColors.indigoTint, 'text': AppColors.indigo},
    {'value': 'high', 'label': 'High', 'bg': AppColors.goldTint, 'text': AppColors.gold},
    {'value': 'urgent', 'label': 'Urgent', 'bg': AppColors.coralTint, 'text': AppColors.coral},
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    _titleCtrl.clear();
    _subjectCtrl.clear();
    _descCtrl.clear();
    setState(() {
      _priority = "normal";
      _image = null;
      _pdf = null;
    });
  }

  Future<void> _handlePickImage() async {
    setState(() => _uploadingImage = true);
    try {
      final uploadSvc = ref.read(uploadServiceProvider);
      final file = await uploadSvc.pickAndUploadImage();
      if (file != null) setState(() => _image = file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _handlePickPdf() async {
    setState(() => _uploadingPdf = true);
    try {
      final uploadSvc = ref.read(uploadServiceProvider);
      final file = await uploadSvc.pickAndUploadPDF();
      if (file != null) setState(() => _pdf = file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _uploadingPdf = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty || _subjectCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in title, subject, and description")),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post("/api/doubts", data: {
        "title": _titleCtrl.text.trim(),
        "description": _descCtrl.text.trim(),
        "subject": _subjectCtrl.text.trim(),
        "priority": _priority,
        "imageUrl": _image?.url,
        "imageName": _image?.name,
        "pdfUrl": _pdf?.url,
        "pdfName": _pdf?.name,
      });

      if (response.data['success'] == true) {
        _reset();
        widget.onSuccess();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['error'] ?? "Unknown error")),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool get _isValid =>
      _titleCtrl.text.trim().isNotEmpty &&
      _subjectCtrl.text.trim().isNotEmpty &&
      _descCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: Stack(
        children: [
          // Backdrop
          AnimatedOpacity(
            opacity: widget.visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(color: Colors.black.withValues(alpha: 0.6)),
            ),
          ),

          // Modal Sheet
          AnimatedSlide(
            offset: widget.visible ? Offset.zero : const Offset(0, 1),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                bottom: true,
                child: Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: kGlassModalFillGradient,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: kGlassCardShadow,
                      border: Border(
                        top: BorderSide(color: Color(0x33FFFFFF), width: 1),
                      ),
                    ),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.88,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: AppRadius.pillBorder,
                            ),
                          ),
                        ),

                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.border)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Ask a Doubt",
                                style: AppTypography.h3.copyWith(fontSize: 17, color: AppColors.ink),
                              ),
                              AnimatedPressable(
                                pressScale: 0.9,
                                onPress: widget.onClose,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: AppRadius.smBorder,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(LucideIcons.x, size: 18, color: AppColors.inkMuted),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Scrollable Body
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Title *",
                                  style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
                                ),
                                const SizedBox(height: 6),
                                _buildTextInput(
                                  controller: _titleCtrl,
                                  hintText: "Brief summary…",
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                Text(
                                  "Subject *",
                                  style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
                                ),
                                const SizedBox(height: 6),
                                _buildTextInput(
                                  controller: _subjectCtrl,
                                  hintText: "e.g., Mathematics, Physics…",
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                Text(
                                  "Priority",
                                  style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _priorities.map((p) {
                                    final isSelected = _priority == p['value'];
                                    return AnimatedPressable(
                                      pressScale: 0.95,
                                      onPress: () => setState(() => _priority = p['value'] as String),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected ? p['bg'] as Color : AppColors.surfaceMuted,
                                          borderRadius: AppRadius.mdBorder,
                                        ),
                                        child: Text(
                                          p['label'] as String,
                                          style: AppTypography.label.copyWith(
                                            fontSize: 12,
                                            color: isSelected ? p['text'] as Color : AppColors.inkMuted,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                Text(
                                  "Description *",
                                  style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0x1FFFFFFF),
                                        Color(0x0DFFFFFF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0x33FFFFFF), width: 1.0),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1F000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _descCtrl,
                                    maxLines: 4,
                                    minLines: 3,
                                    cursorColor: const Color(0xFF2EE6C5),
                                    style: AppTypography.body.copyWith(fontSize: 14, color: AppColors.ink),
                                    decoration: InputDecoration(
                                      hintText: "Explain your doubt in detail…",
                                      hintStyle: AppTypography.body.copyWith(color: AppColors.inkFaint, fontSize: 14),
                                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                Text(
                                  "Attachments (Optional)",
                                  style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _image != null
                                          ? Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: AppRadius.mdBorder,
                                                  child: Image.network(
                                                    _image!.url,
                                                    height: 96,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 6,
                                                  right: 6,
                                                  child: GestureDetector(
                                                    onTap: () => setState(() => _image = null),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.coral,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(LucideIcons.x, size: 12, color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : AnimatedPressable(
                                              pressScale: 0.95,
                                              onPress: _uploadingImage ? null : _handlePickImage,
                                              child: Container(
                                                height: 96,
                                                decoration: BoxDecoration(
                                                  color: AppColors.surface,
                                                  border: Border.all(color: AppColors.border, width: 1.5),
                                                  borderRadius: AppRadius.mdBorder,
                                                ),
                                                alignment: Alignment.center,
                                                child: _uploadingImage
                                                    ? CircularProgressIndicator(color: AppColors.indigo, strokeWidth: 2)
                                                    : Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(LucideIcons.image, size: 20, color: AppColors.inkFaint),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            "Add Image",
                                                            style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _pdf != null
                                          ? Container(
                                              height: 96,
                                              padding: const EdgeInsets.all(AppSpacing.md),
                                              decoration: BoxDecoration(
                                                color: AppColors.coralTint,
                                                border: Border.all(color: AppColors.coral.withValues(alpha: 0.4), width: 1.5),
                                                borderRadius: AppRadius.mdBorder,
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(LucideIcons.fileText, size: 14, color: AppColors.coral),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          _pdf!.name,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: AppTypography.label.copyWith(fontSize: 11.5, color: AppColors.coral),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  AnimatedPressable(
                                                    pressScale: 0.93,
                                                    onPress: () => setState(() => _pdf = null),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.coral,
                                                        borderRadius: AppRadius.smBorder,
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          const Icon(LucideIcons.trash2, size: 11, color: Colors.white),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            "Remove",
                                                            style: AppTypography.label.copyWith(fontSize: 10, color: Colors.white),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : AnimatedPressable(
                                              pressScale: 0.95,
                                              onPress: _uploadingPdf ? null : _handlePickPdf,
                                              child: Container(
                                                height: 96,
                                                decoration: BoxDecoration(
                                                  color: AppColors.surface,
                                                  border: Border.all(color: AppColors.border, width: 1.5),
                                                  borderRadius: AppRadius.mdBorder,
                                                ),
                                                alignment: Alignment.center,
                                                child: _uploadingPdf
                                                    ? CircularProgressIndicator(color: AppColors.coral, strokeWidth: 2)
                                                    : Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(LucideIcons.fileText, size: 20, color: AppColors.inkFaint),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            "Add PDF",
                                                            style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xl),
                              ],
                            ),
                          ),
                        ),

                        // Footer Buttons
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: AppColors.border)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: "Cancel",
                                  variant: AppButtonVariant.secondary,
                                  onPress: widget.onClose,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppButton(
                                  label: "Post",
                                  icon: LucideIcons.send,
                                  variant: AppButtonVariant.primary,
                                  onPress: _handleSubmit,
                                  loading: _submitting,
                                  disabled: !_isValid,
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x1FFFFFFF),
            Color(0x0DFFFFFF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33FFFFFF), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        cursorColor: const Color(0xFF2EE6C5),
        style: AppTypography.body.copyWith(fontSize: 14, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.body.copyWith(color: AppColors.inkFaint, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
