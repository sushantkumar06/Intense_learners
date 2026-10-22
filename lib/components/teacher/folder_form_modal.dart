import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:coaching_app_flutter/theme/app_theme.dart';
import '../../../models/teacher_video.dart';
import '../../../services/api_client.dart';

class FolderFormModal extends ConsumerStatefulWidget {
  final TeacherVideoFolder? folder;
  final VoidCallback onSuccess;

  const FolderFormModal({super.key, this.folder, required this.onSuccess});

  @override
  ConsumerState<FolderFormModal> createState() => _FolderFormModalState();
}

class _FolderFormModalState extends ConsumerState<FolderFormModal> {
  late String name;
  late String subject;
  late String className;
  late String chapter;
  late String description;
  late String thumbnailUrl;
  late String youtubePlaylistId;
  late bool isPublic;

  bool thumbError = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    final f = widget.folder;
    name = f?.name ?? '';
    subject = f?.subject ?? '';
    className = f?.className ?? '';
    chapter = f?.chapter ?? '';
    description = f?.description ?? '';
    thumbnailUrl = f?.thumbnail ?? '';
    youtubePlaylistId = f?.youtubePlaylistId ?? '';
    isPublic = f?.isPublic ?? true;
  }

  Future<void> _handleSubmit() async {
    if (name.trim().isEmpty || subject.trim().isEmpty || className.trim().isEmpty || chapter.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }
    setState(() => busy = true);
    try {
      final payload = {
        "name": name.trim(),
        "subject": subject.trim(),
        "class": className.trim(),
        "chapter": chapter.trim(),
        "description": description.trim(),
        "thumbnail": thumbnailUrl.trim(),
        "youtubePlaylistId": youtubePlaylistId.trim(),
        "isPublic": isPublic,
      };

      final api = ref.read(dioProvider);
      final response = widget.folder != null
          ? await api.patch("/api/teacher/video-folders/${widget.folder!.id}", data: payload)
          : await api.post("/api/teacher/video-folders", data: payload);

      final data = response.data;
      if (data['error'] != null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'])));
      } else {
        widget.onSuccess();
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.folder != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          gradient: kGlassModalFillGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
          boxShadow: kGlassCardShadow,
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x1FFFFFFF)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isEdit ? "Edit Folder" : "Create New Folder", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(isEdit ? "Update folder details" : "Fill in details for your new folder", style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
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
          
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Folder Name *"),
                  _buildTextField(name, (v) => name = v, placeholder: "e.g., Wave Optics Complete"),
                  
                  _buildLabel("Subject *"),
                  _buildTextField(subject, (v) => subject = v, placeholder: "e.g., Physics, Chemistry"),

                  _buildLabel("Class *"),
                  _buildTextField(className, (v) => className = v, placeholder: "e.g., 12th, JEE, NEET"),

                  _buildLabel("Chapter *"),
                  _buildTextField(chapter, (v) => chapter = v, placeholder: "e.g., Chapter 10 - Wave Optics"),

                  _buildLabel("Description"),
                  _buildTextField(description, (v) => description = v, placeholder: "Brief description...", minLines: 3, maxLines: 5),

                  _buildLabel("Thumbnail Image URL"),
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      border: Border.all(color: const Color(0x26FFFFFF), width: 1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.link, size: 15, color: AppColors.inkMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: thumbnailUrl)..selection = TextSelection.collapsed(offset: thumbnailUrl.length),
                            onChanged: (v) { thumbnailUrl = v; thumbError = false; },
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              hintText: "https://...",
                              hintStyle: TextStyle(color: AppColors.inkFaint),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text("Paste any image URL. Leave blank to auto-use the first video's thumbnail.", style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                  const SizedBox(height: 16),

                  if (thumbnailUrl.isNotEmpty)
                    Container(
                      height: 128,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x26FFFFFF), width: 1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: !thumbError
                          ? Image.network(thumbnailUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) {
                              WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => thumbError = true); });
                              return const SizedBox();
                            })
                          : Container(color: const Color(0x14FFFFFF), alignment: Alignment.center, child: const Text("Couldn't load this image", style: TextStyle(fontSize: 12, color: AppColors.inkMuted))),
                    ),

                  _buildLabel("YouTube Playlist ID (optional)"),
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      border: Border.all(color: const Color(0x26FFFFFF), width: 1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.play, size: 15, color: Color(0xFFFF6B6B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: youtubePlaylistId)..selection = TextSelection.collapsed(offset: youtubePlaylistId.length),
                            onChanged: (v) => youtubePlaylistId = v,
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              hintText: "e.g. PLxxxxxxxxxxxxxxxxxxxx",
                              hintStyle: TextStyle(color: AppColors.inkFaint),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text("From a playlist URL: youtube.com/playlist?list=THIS_PART", style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                  const SizedBox(height: 16),

                  const Text("Visibility", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isPublic = true),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isPublic ? const Color(0x2E2EE6C5) : const Color(0x14FFFFFF),
                              border: Border.all(color: isPublic ? const Color(0xFF2EE6C5) : const Color(0x26FFFFFF), width: 1.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.globe, size: 16, color: Color(0xFF2EE6A8)),
                                SizedBox(width: 8),
                                Text("Public", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isPublic = false),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: !isPublic ? const Color(0x2E2EE6C5) : const Color(0x14FFFFFF),
                              border: Border.all(color: !isPublic ? const Color(0xFF2EE6C5) : const Color(0x26FFFFFF), width: 1.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.lock, size: 16, color: Color(0xFFFFD166)),
                                SizedBox(width: 8),
                                Text("Private", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x1FFFFFFF)))),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                    onTap: busy ? null : _handleSubmit,
                    child: Opacity(
                      opacity: busy ? 0.45 : 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2EE6C5),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: busy ? null : const [
                            BoxShadow(
                              color: Color(0x522EE6C5),
                              blurRadius: 18,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: busy
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF0F2027), strokeWidth: 2))
                            : Text(isEdit ? "Update Folder" : "Create Folder", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F2027))),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }

  Widget _buildTextField(String value, Function(String) onChanged, {required String placeholder, int minLines = 1, int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: TextField(
        controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
        onChanged: onChanged,
        minLines: minLines,
        maxLines: maxLines,
        cursorColor: const Color(0xFF2EE6C5),
        style: const TextStyle(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: AppColors.inkFaint),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
