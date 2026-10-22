import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:coaching_app_flutter/theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../services/upload_service.dart';

class CreateAssignmentModal extends ConsumerStatefulWidget {
  const CreateAssignmentModal({super.key});

  @override
  ConsumerState<CreateAssignmentModal> createState() =>
      _CreateAssignmentModalState();
}

class _CreateAssignmentModalState extends ConsumerState<CreateAssignmentModal> {
  String _title = "";
  String _description = "";
  String _subject = "";
  String _className = "";
  String _dueDate = "";

  Map<String, String>? _uploadedFile;
  bool _uploadingFile = false;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dueDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _handlePickFile() async {
    setState(() => _uploadingFile = true);
    try {
      final uploadSvc = ref.read(uploadServiceProvider);
      final file = await uploadSvc.pickAndUploadPDF();
      if (file != null) {
        setState(() {
          _uploadedFile = {
            'url': file.url,
            'name': file.name,
            'size': file.size,
            'type': file.type ?? 'pdf',
          };
        });
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload failed: $err")));
      }
    } finally {
      if (mounted) setState(() => _uploadingFile = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (_title.trim().isEmpty ||
        _description.trim().isEmpty ||
        _subject.trim().isEmpty ||
        _className.trim().isEmpty ||
        _dueDate.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    if (_uploadedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload the assignment PDF")),
      );
      return;
    }

    // Basic date parsing validation (Format YYYY-MM-DD)
    try {
      final parts = _dueDate.split('-');
      if (parts.length != 3) throw FormatException();
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      final selectedDate = DateTime(year, month, day, 23, 59, 59);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (selectedDate.isBefore(today)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Due date cannot be in the past")),
        );
        return;
      }

      setState(() => _creating = true);
      final payload = {
        'title': _title,
        'description': _description,
        'subject': _subject,
        'class': _className,
        'dueDate': selectedDate.toIso8601String(),
        'fileUrl': _uploadedFile!['url'],
        'fileName': _uploadedFile!['name'],
        'fileSize': _uploadedFile!['size'],
      };

      final response = await ref
          .read(dioProvider)
          .post("/api/teacher/assignments", data: payload);

      if (response.data['success'] == true) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        throw Exception(
          response.data['error'] ?? "Failed to create assignment",
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required Function(String) onChanged,
    String placeholder = "",
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x1FFFFFFF),
                Color(0x0DFFFFFF),
              ],
            ),
            border: Border.all(color: const Color(0x33FFFFFF), width: 1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: TextField(
            controller: TextEditingController(text: value)
              ..selection = TextSelection.collapsed(offset: value.length),
            onChanged: onChanged,
            maxLines: maxLines,
            keyboardType: keyboardType,
            cursorColor: const Color(0xFF2EE6C5),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                color: AppColors.inkFaint,
                fontSize: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
        ),
      ],
    );
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x1FFFFFFF))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Create New Assignment",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(
                    LucideIcons.x,
                    size: 22,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    label: "Assignment Title *",
                    value: _title,
                    onChanged: (v) => _title = v,
                    placeholder: "e.g., Chapter 5 - Thermodynamics Problems",
                  ),
                  _buildTextField(
                    label: "Description *",
                    value: _description,
                    onChanged: (v) => _description = v,
                    placeholder: "Describe the assignment...",
                    maxLines: 4,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: "Subject *",
                          value: _subject,
                          onChanged: (v) => _subject = v,
                          placeholder: "e.g., Physics",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: "Class *",
                          value: _className,
                          onChanged: (v) => _className = v,
                          placeholder: "e.g., Class 12",
                        ),
                      ),
                    ],
                  ),

                  _buildTextField(
                    label: "Due Date * (YYYY-MM-DD)",
                    value: _dueDate,
                    onChanged: (v) => _dueDate = v,
                    placeholder: "2024-12-31",
                  ),
                  Transform.translate(
                    offset: const Offset(0, -12),
                    child: const Text(
                      "Due date must be today or in the future",
                      style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                    ),
                  ),

                  const Text(
                    "Assignment File (PDF) *",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_uploadedFile != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: const Color(0x14FFFFFF),
                        border: Border.all(
                          color: const Color(0x662EE6C5),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0x2E2EE6C5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              LucideIcons.fileText,
                              size: 18,
                              color: Color(0xFF2EE6C5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _uploadedFile!['name']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${_uploadedFile!['size']}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _uploadedFile = null),
                            child: const Icon(
                              LucideIcons.trash2,
                              size: 18,
                              color: Color(0xFFFF6B6B),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _uploadingFile ? null : _handlePickFile,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0x0FFFFFFF),
                          border: Border.all(
                            color: const Color(0x26FFFFFF),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            if (_uploadingFile) ...[
                              const CircularProgressIndicator(
                                color: Color(0xFF2EE6C5),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Uploading...",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2EE6C5),
                                ),
                              ),
                            ] else ...[
                              const Icon(
                                LucideIcons.upload,
                                size: 28,
                                color: AppColors.inkMuted,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Tap to upload assignment PDF",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "PDF only • Max 16MB • Required",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  // Alert Banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x1A2EE6C5),
                      border: Border.all(
                        color: const Color(0x4D2EE6C5),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            LucideIcons.alertCircle,
                            size: 16,
                            color: Color(0xFF2EE6C5),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Students will submit their answers as PDF files and can discuss solutions in comments.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2EE6C5),
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

          // Footer Buttons
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0x14FFFFFF),
                        border: Border.all(
                          color: const Color(0x33FFFFFF),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: (_creating || _uploadedFile == null)
                        ? null
                        : _handleSubmit,
                    child: Opacity(
                      opacity: (_creating || _uploadedFile == null) ? 0.45 : 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2EE6C5),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: (_creating || _uploadedFile == null)
                              ? null
                              : const [
                                  BoxShadow(
                                    color: Color(0x522EE6C5),
                                    blurRadius: 18,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                        ),
                        alignment: Alignment.center,
                        child: _creating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF0F2027),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.plus,
                                    size: 16,
                                    color: Color(0xFF0F2027),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Create Assignment",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F2027),
                                    ),
                                  ),
                                ],
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
