import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:coaching_app_flutter/theme/app_theme.dart';
import '../../models/teacher_note.dart';
import '../../services/api_client.dart';
import '../../services/upload_service.dart';

class NoteFormModal extends ConsumerStatefulWidget {
  final String mode; // "create" | "edit"
  final TeacherNote? note;

  const NoteFormModal({super.key, required this.mode, this.note});

  @override
  ConsumerState<NoteFormModal> createState() => _NoteFormModalState();
}

class _NoteFormModalState extends ConsumerState<NoteFormModal> {
  late String _title;
  late String _description;
  late String _subject;
  late String _className;
  late String _topic;
  late String _chapter;
  late String _price;
  late bool _isPublished;
  late bool _isPinned;

  Map<String, String>? _uploadedFile;
  Map<String, String>? _uploadedThumb;

  bool _uploadingFile = false;
  bool _uploadingThumb = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = widget.note?.title ?? "";
    _description = widget.note?.description ?? "";
    _subject = widget.note?.subject ?? "";
    _className = widget.note?.className ?? "";
    _topic = widget.note?.topic ?? "";
    _chapter = widget.note?.chapter ?? "";
    _price = (widget.note?.price ?? 30).toInt().toString();
    _isPublished = widget.note?.isPublished ?? true;
    _isPinned = widget.note?.isPinned ?? false;

    if (widget.note != null) {
      _uploadedFile = {
        'url': widget.note!.fileUrl,
        'name': widget.note!.fileName,
        'size': widget.note!.fileSize,
        'type': widget.note!.fileType,
      };
      if (widget.note!.thumbnailUrl != null) {
        _uploadedThumb = {
          'url': widget.note!.thumbnailUrl!,
          'name': 'Current thumbnail',
        };
      }
    }
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

  Future<void> _handlePickThumb() async {
    setState(() => _uploadingThumb = true);
    try {
      final uploadSvc = ref.read(uploadServiceProvider);
      final file = await uploadSvc.pickAndUploadImage();
      if (file != null) {
        setState(() {
          _uploadedThumb = {
            'url': file.url,
            'name': file.name,
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
      if (mounted) setState(() => _uploadingThumb = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (_title.trim().isEmpty ||
        _subject.trim().isEmpty ||
        _className.trim().isEmpty ||
        _uploadedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields and upload a file"),
        ),
      );
      return;
    }
    final priceNum = int.tryParse(_price) ?? 0;
    if (priceNum < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Price cannot be negative")));
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = {
        'title': _title,
        'description': _description.isEmpty ? null : _description,
        'subject': _subject,
        'class': _className,
        'topic': _topic.isEmpty ? null : _topic,
        'chapter': _chapter.isEmpty ? null : _chapter,
        'fileUrl': _uploadedFile!['url'],
        'fileName': _uploadedFile!['name'],
        'fileType': _uploadedFile!['type'],
        'fileSize': _uploadedFile!['size'],
        'thumbnailUrl': _uploadedThumb?['url'],
        'price': priceNum,
        'isPublished': _isPublished,
        'isPinned': _isPinned,
      };

      if (widget.mode == "edit") {
        payload['noteId'] = widget.note!.id;
      }

      final response = await (widget.mode == "edit"
          ? ref.read(dioProvider).put("/api/teacher/notes", data: payload)
          : ref.read(dioProvider).post("/api/teacher/notes", data: payload));

      final data = response.data;
      if (data['success'] == true) {
        if (mounted) {
          Navigator.of(context).pop(TeacherNote.fromJson(data['note']));
        }
      } else {
        throw Exception(data['error'] ?? "Failed to save note");
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
    final isEdit = widget.mode == "edit";
    return Container(
      decoration: const BoxDecoration(
        gradient: kGlassModalFillGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
        boxShadow: kGlassCardShadow,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? "Edit Note" : "Upload New Note",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEdit
                          ? "Update details below"
                          : "Fill in details and upload your file",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
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
                    label: "Title *",
                    value: _title,
                    onChanged: (v) => _title = v,
                    placeholder: "e.g., Organic Chemistry Chapter 5",
                  ),
                  _buildTextField(
                    label: "Description",
                    value: _description,
                    onChanged: (v) => _description = v,
                    placeholder: "Brief description of the note content...",
                    maxLines: 3,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: "Subject *",
                          value: _subject,
                          onChanged: (v) => _subject = v,
                          placeholder: "e.g., Chemistry",
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

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: "Topic",
                          value: _topic,
                          onChanged: (v) => _topic = v,
                          placeholder: "e.g., Alcohols",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: "Chapter",
                          value: _chapter,
                          onChanged: (v) => _chapter = v,
                          placeholder: "e.g., Chapter 11",
                        ),
                      ),
                    ],
                  ),

                  _buildTextField(
                    label: "Hardcopy Price (₹) *",
                    value: _price,
                    onChanged: (v) => _price = v,
                    placeholder: "30",
                    keyboardType: TextInputType.number,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -12),
                    child: const Text(
                      "Price when students order a physical hardcopy. Default ₹30.",
                      style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                    ),
                  ),

                  const Text(
                    "Upload File (PDF or Image) *",
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
                      margin: const EdgeInsets.only(bottom: 16),
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
                                  "${_uploadedFile!['size']} • ${_uploadedFile!['type']!.toUpperCase()}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            LucideIcons.checkCircle,
                            size: 18,
                            color: Color(0xFF2EE6A8),
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
                        padding: const EdgeInsets.symmetric(vertical: 20),
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
                            if (_uploadingFile)
                              const CircularProgressIndicator(
                                color: Color(0xFF2EE6C5),
                              )
                            else ...[
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0x2E2EE6C5),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  LucideIcons.upload,
                                  size: 24,
                                  color: Color(0xFF2EE6C5),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Click to select file",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                "PDF, DOCX, PNG up to 10MB",
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

                  const Text(
                    "Thumbnail (Optional)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_uploadedThumb != null)
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
                              LucideIcons.image,
                              size: 18,
                              color: Color(0xFF2EE6C5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _uploadedThumb!['name']!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _uploadedThumb = null),
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
                      onTap: _uploadingThumb ? null : _handlePickThumb,
                      child: Container(
                        padding: const EdgeInsets.all(16),
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
                            if (_uploadingThumb)
                              const CircularProgressIndicator(
                                color: Color(0xFF2EE6C5),
                              )
                            else ...[
                              const Icon(
                                LucideIcons.image,
                                size: 22,
                                color: AppColors.inkMuted,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Upload cover image • Max 4MB",
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

                  // Switches
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      border: Border.all(
                        color: const Color(0x26FFFFFF),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Publish immediately",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    "Students can see this note right away",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isPublished,
                              onChanged: (v) =>
                                  setState(() => _isPublished = v),
                              activeTrackColor: const Color(0xFF2EE6C5),
                              activeThumbColor: const Color(0xFF0F2027),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Pin to top",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    "This note appears first in the list",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isPinned,
                              onChanged: (v) => setState(() => _isPinned = v),
                              activeTrackColor: const Color(0xFF2EE6C5),
                              activeThumbColor: const Color(0xFF0F2027),
                            ),
                          ],
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
                    onTap: (_saving || _uploadedFile == null)
                        ? null
                        : _handleSubmit,
                    child: Opacity(
                      opacity: (_saving || _uploadedFile == null) ? 0.45 : 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2EE6C5),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: (_saving || _uploadedFile == null)
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
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF0F2027),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEdit ? "Save Changes" : "Upload Note",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F2027),
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
