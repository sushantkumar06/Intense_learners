import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:coaching_app_flutter/theme/app_theme.dart';
import '../../models/assignment.dart';
import '../../services/api_client.dart';
import '../../services/upload_service.dart';

class SubmitAssignmentModal extends ConsumerStatefulWidget {
  final StudentAssignment assignment;
  final Function(String assignmentId, AssignmentSubmission submission) onSuccess;

  const SubmitAssignmentModal({
    super.key,
    required this.assignment,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required StudentAssignment assignment,
    required Function(String assignmentId, AssignmentSubmission submission) onSuccess,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SubmitAssignmentModal(
          assignment: assignment,
          onSuccess: onSuccess,
        ),
      ),
    );
  }

  @override
  ConsumerState<SubmitAssignmentModal> createState() => _SubmitAssignmentModalState();
}

class _SubmitAssignmentModalState extends ConsumerState<SubmitAssignmentModal> {
  UploadedFile? _uploadedFile;
  String _remarks = "";
  bool _uploading = false;
  bool _submitting = false;

  Future<void> _handlePickFile() async {
    setState(() => _uploading = true);
    try {
      final dio = ref.read(dioProvider);
      final uploadService = UploadService(dio);
      final file = await uploadService.pickAndUploadPDF();
      if (file != null) {
        setState(() => _uploadedFile = file);
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $err")),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (_uploadedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing file. Please upload your assignment PDF.")),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        "/api/student/assignments",
        data: {
          "assignmentId": widget.assignment.id,
          "fileUrl": _uploadedFile!.url,
          "fileName": _uploadedFile!.name,
          "fileSize": _uploadedFile!.size,
          "remarks": _remarks.isNotEmpty ? _remarks : null,
        },
      );
      final data = response.data;
      if (data != null && data['success'] == true) {
        widget.onSuccess(widget.assignment.id, AssignmentSubmission.fromJson(data['submission']));
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception(data?['error'] ?? "Unknown error");
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting: $err")),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: kGlassModalFillGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
        boxShadow: kGlassCardShadow,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0x1FFFFFFF))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Submit Assignment",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            widget.assignment.title,
                            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(LucideIcons.x, size: 22, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Upload Your Solution (PDF) *",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    if (_uploadedFile != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x14FFFFFF),
                          border: Border.all(color: const Color(0x662EE6C5), width: 1.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0x1F2EE6C5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(LucideIcons.fileText, size: 20, color: Color(0xFF2EE6C5)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _uploadedFile!.name,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _uploadedFile!.size,
                                    style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _uploadedFile = null),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(LucideIcons.trash2, size: 18, color: Color(0xFFFF6B6B)),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _uploading ? null : _handlePickFile,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: const Color(0x0FFFFFFF),
                            border: Border.all(color: const Color(0x26FFFFFF), width: 1.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: _uploading
                              ? const Column(
                                  children: [
                                    CircularProgressIndicator(color: Color(0xFF2EE6C5)),
                                    SizedBox(height: 8),
                                    Text("Uploading…", style: TextStyle(color: Color(0xFF2EE6C5), fontWeight: FontWeight.w500, fontSize: 14)),
                                  ],
                                )
                              : const Column(
                                  children: [
                                    Icon(LucideIcons.upload, size: 32, color: AppColors.inkMuted),
                                    SizedBox(height: 8),
                                    Text("Tap to upload your solution PDF", style: TextStyle(color: AppColors.inkMuted, fontSize: 14)),
                                    SizedBox(height: 4),
                                    Text("PDF only (Max 16MB)", style: TextStyle(color: AppColors.inkFaint, fontSize: 12)),
                                  ],
                                ),
                        ),
                      ),

                    const SizedBox(height: 20),
                    const Text(
                      "Remarks (Optional)",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (val) => setState(() => _remarks = val),
                      minLines: 3,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      cursorColor: const Color(0xFF2EE6C5),
                      decoration: InputDecoration(
                        hintText: "Add any notes about your submission…",
                        hintStyle: const TextStyle(fontSize: 14, color: AppColors.inkFaint),
                        filled: true,
                        fillColor: const Color(0x14FFFFFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0x26FFFFFF), width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0x26FFFFFF), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0x992EE6C5), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x1A2EE6C5),
                        border: Border.all(color: const Color(0x402EE6C5), width: 1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(LucideIcons.sparkles, size: 16, color: Color(0xFF2EE6C5)),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Make sure your PDF is clear and readable. You can discuss solutions with classmates in the comments!",
                              style: TextStyle(fontSize: 12, color: Color(0xFF2EE6C5)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0x14FFFFFF),
                            border: Border.all(color: const Color(0x33FFFFFF), width: 1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: const Text("Cancel", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: (_uploadedFile == null || _submitting || _uploading) ? null : _handleSubmit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: (_uploadedFile == null || _submitting || _uploading)
                                ? const Color(0xFF2EE6C5).withValues(alpha: 0.35)
                                : const Color(0xFF2EE6C5),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: (_uploadedFile == null || _submitting || _uploading) ? null : kAccentGlowShadow,
                          ),
                          alignment: Alignment.center,
                          child: _submitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Color(0xFF0F2027), strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.send,
                                      size: 16,
                                      color: (_uploadedFile == null || _submitting || _uploading) ? AppColors.inkMuted : const Color(0xFF0F2027),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Submit",
                                      style: TextStyle(
                                        color: (_uploadedFile == null || _submitting || _uploading) ? AppColors.inkMuted : const Color(0xFF0F2027),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
