import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:coaching_app_flutter/theme/app_theme.dart';
import '../../models/assignment.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/upload_service.dart';

class CommentsModal extends ConsumerStatefulWidget {
  final StudentAssignment assignment;

  const CommentsModal({
    super.key,
    required this.assignment,
  });

  static Future<void> show(BuildContext context, {required StudentAssignment assignment}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.9, // maxHeight: "90%"
          child: CommentsModal(assignment: assignment),
        ),
      ),
    );
  }

  @override
  ConsumerState<CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends ConsumerState<CommentsModal> {
  List<AssignmentComment> _comments = [];
  bool _loading = true;
  String _newComment = "";
  late final TextEditingController _commentController;
  UploadedFile? _uploadedFile;
  bool _uploading = false;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get("/api/assignments/comments?assignmentId=${widget.assignment.id}");
      final data = response.data;
      if (data != null && data['success'] == true) {
        final List<dynamic> commentsData = data['comments'] ?? [];
        if (mounted) {
          setState(() {
            _comments = commentsData.map((c) => AssignmentComment.fromJson(c)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching comments: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handlePickFile() async {
    setState(() => _uploading = true);
    try {
      final dio = ref.read(dioProvider);
      final uploadService = UploadService(dio);
      final file = await uploadService.pickAndUploadPDF(); // The RN code uses pickAndUploadPDF
      if (file != null) {
        setState(() => _uploadedFile = file);
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $err")));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _handlePost() async {
    if (_newComment.trim().isEmpty && _uploadedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write a comment or attach a file")),
      );
      return;
    }
    setState(() => _posting = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        "/api/assignments/comments",
        data: {
          "assignmentId": widget.assignment.id,
          "content": _newComment,
          "fileUrl": _uploadedFile?.url,
          "fileName": _uploadedFile?.name,
          "fileSize": _uploadedFile?.size,
        },
      );
      final data = response.data;
      if (data != null && data['success'] == true) {
        final newC = AssignmentComment.fromJson(data['comment']);
        setState(() {
          _comments = [newC, ..._comments];
          _newComment = "";
          _commentController.clear();
          _uploadedFile = null;
        });
      } else {
        throw Exception(data?['error'] ?? "Unknown error");
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error posting: $err")));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _handleLike(String commentId) async {
    // optimistic
    setState(() {
      _comments = _comments.map((c) {
        if (c.id == commentId) return c.copyWith(likes: c.likes + 1);
        return c;
      }).toList();
    });

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.patch(
        "/api/assignments/comments",
        data: {"commentId": commentId, "action": "like"},
      );
      final data = response.data;
      if (data != null && data['success'] == true) {
        setState(() {
          _comments = _comments.map((c) {
            if (c.id == commentId) return c.copyWith(likes: data['comment']['likes']);
            return c;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error liking comment: $e");
    }
  }

  Future<void> _handleDelete(String commentId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete comment?"),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // optimistic
    setState(() {
      _comments = _comments.where((c) => c.id != commentId).toList();
    });

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.delete("/api/assignments/comments?id=$commentId");
      final data = response.data;
      if (data == null || data['success'] != true) {
        _fetchComments(); // revert on failure
      }
    } catch (e) {
      debugPrint("Error deleting comment: $e");
      _fetchComments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: kGlassModalFillGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
        boxShadow: kGlassCardShadow,
      ),
      child: SafeArea(
        top: false,
        child: Column(
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
                        const Row(
                          children: [
                            Icon(LucideIcons.messageSquare, size: 18, color: Color(0xFF2EE6C5)),
                            SizedBox(width: 8),
                            Text("Discussion", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
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

            // Comments List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2EE6C5)))
                  : _comments.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.messageSquare, size: 40, color: AppColors.inkMuted),
                              SizedBox(height: 12),
                              Text("No comments yet", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                              SizedBox(height: 4),
                              Text("Be the first to start the discussion!", style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            final isTeacher = comment.user['role'] == 'TEACHER';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0x14FFFFFF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0x26FFFFFF)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0x2E2EE6C5),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0x662EE6C5), width: 1),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    alignment: Alignment.center,
                                    child: (comment.user['avatar'] != null && comment.user['avatar'].toString().isNotEmpty)
                                        ? Image.network(comment.user['avatar'], fit: BoxFit.cover)
                                        : Text(
                                            comment.user['name']?.toString().isNotEmpty == true ? comment.user['name'][0].toUpperCase() : "?",
                                            style: const TextStyle(color: Color(0xFF2EE6C5), fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            Text(
                                              comment.user['name'] ?? "Unknown",
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isTeacher ? const Color(0x2E2EE6C5) : const Color(0x1AFFFFFF),
                                                borderRadius: BorderRadius.circular(9999),
                                              ),
                                              child: Text(
                                                comment.user['role']?.toString() ?? 'STUDENT',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: isTeacher ? const Color(0xFF2EE6C5) : AppColors.inkMuted,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              "${comment.createdAt.day} ${_getMonthAbbr(comment.createdAt.month)}",
                                              style: const TextStyle(fontSize: 10, color: AppColors.inkMuted),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),

                                        if (comment.content.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Text(
                                              comment.content,
                                              style: const TextStyle(fontSize: 14, color: Colors.white),
                                            ),
                                          ),

                                        if (comment.fileUrl != null && comment.fileUrl!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: GestureDetector(
                                              onTap: () => launchUrl(Uri.parse(comment.fileUrl!)),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0x14FFFFFF),
                                                  border: Border.all(color: const Color(0x26FFFFFF)),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(LucideIcons.paperclip, size: 13, color: Color(0xFF2EE6C5)),
                                                    const SizedBox(width: 6),
                                                    ConstrainedBox(
                                                      constraints: const BoxConstraints(maxWidth: 200),
                                                      child: Text(
                                                        comment.fileName ?? "Attachment",
                                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF2EE6C5)),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    const Icon(LucideIcons.externalLink, size: 11, color: Color(0xFF2EE6C5)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),

                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _handleLike(comment.id),
                                              child: Row(
                                                children: [
                                                  const Icon(LucideIcons.thumbsUp, size: 14, color: AppColors.inkMuted),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    comment.likes.toString(),
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkMuted),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            if ((comment.user['id'] ?? comment.user['_id']) ==
                                                (currentUser.user?['id'] ?? currentUser.user?['_id']))
                                              GestureDetector(
                                                onTap: () => _handleDelete(comment.id),
                                                child: const Text("Delete", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFF6B6B))),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
              ),
              child: Column(
                children: [
                  if (_uploadedFile != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x14FFFFFF),
                        border: Border.all(color: const Color(0x4D2EE6C5)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.paperclip, size: 14, color: Color(0xFF2EE6C5)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _uploadedFile!.name,
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _uploadedFile = null),
                            child: const Icon(LucideIcons.x, size: 14, color: Color(0xFFFF6B6B)),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          onChanged: (val) => setState(() => _newComment = val),
                          maxLines: 4,
                          minLines: 1,
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                          cursorColor: const Color(0xFF2EE6C5),
                          decoration: InputDecoration(
                            hintText: "Share your thoughts…",
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
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _uploading ? null : _handlePickFile,
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0x14FFFFFF),
                            border: Border.all(color: const Color(0x26FFFFFF), width: 1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: _uploading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF2EE6C5), strokeWidth: 2))
                              : const Icon(LucideIcons.paperclip, size: 18, color: AppColors.inkMuted),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: ((_newComment.trim().isEmpty && _uploadedFile == null) || _posting) ? null : _handlePost,
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: ((_newComment.trim().isEmpty && _uploadedFile == null) || _posting) 
                                ? const Color(0xFF2EE6C5).withValues(alpha: 0.35) 
                                : const Color(0xFF2EE6C5),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: ((_newComment.trim().isEmpty && _uploadedFile == null) || _posting)
                                ? null
                                : const [
                                    BoxShadow(
                                      color: Color(0x522EE6C5),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                          ),
                          alignment: Alignment.center,
                          child: _posting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF0F2027), strokeWidth: 2))
                              : const Icon(LucideIcons.send, size: 18, color: Color(0xFF0F2027)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }
}
