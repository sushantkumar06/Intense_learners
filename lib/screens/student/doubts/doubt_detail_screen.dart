import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../components/safe_back_scope.dart';
import '../../../components/ui/ui.dart';
import '../../../models/doubt.dart';
import '../../../services/api_client.dart';
import '../../../services/upload_service.dart';
import '../../../theme/app_theme.dart';

String _formatTimeAgo(String d) {
  try {
    final dt = DateTime.parse(d).toLocal();
    final s = DateTime.now().difference(dt).inSeconds;
    if (s < 60) return "just now";
    final m = s ~/ 60;
    if (m < 60) return "${m}m ago";
    final h = m ~/ 60;
    if (h < 24) return "${h}h ago";
    final dy = h ~/ 24;
    if (dy < 7) return "${dy}d ago";
    final w = dy ~/ 7;
    if (w < 4) return "${w}w ago";
    return "${dt.day}/${dt.month}/${dt.year}";
  } catch (_) {
    return d;
  }
}

List<DoubtReply> _sortReplies(List<DoubtReply> replies) {
  final list = List<DoubtReply>.from(replies);
  list.sort((a, b) {
    if (a.user.role == "TEACHER" && b.user.role != "TEACHER") return -1;
    if (a.user.role != "TEACHER" && b.user.role == "TEACHER") return 1;
    if (a.isPinned && !b.isPinned) return -1;
    if (!a.isPinned && b.isPinned) return 1;
    try {
      return DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt));
    } catch (_) {
      return 0;
    }
  });
  return list;
}

AppBadgeTone _priorityTone(String priority) {
  switch (priority.toLowerCase()) {
    case 'urgent':
      return AppBadgeTone.danger;
    case 'high':
      return AppBadgeTone.gold;
    case 'low':
      return AppBadgeTone.success;
    case 'normal':
    default:
      return AppBadgeTone.brand;
  }
}

class DoubtDetailScreen extends ConsumerStatefulWidget {
  final Doubt initialDoubt;
  const DoubtDetailScreen({super.key, required this.initialDoubt});

  @override
  ConsumerState<DoubtDetailScreen> createState() => _DoubtDetailScreenState();
}

class _DoubtDetailScreenState extends ConsumerState<DoubtDetailScreen> {
  late Doubt _doubt;
  final TextEditingController _replyCtrl = TextEditingController();
  UploadedFile? _replyImage;
  UploadedFile? _replyPdf;
  bool _uploadingImage = false;
  bool _uploadingPdf = false;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _doubt = widget.initialDoubt;
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleUpvote() async {
    final willUpvote = !_doubt.hasUpvoted;
    setState(() {
      _doubt = _doubt.copyWith(
        hasUpvoted: willUpvote,
        stats: DoubtStats(
          totalReplies: _doubt.stats.totalReplies,
          totalUpvotes: willUpvote ? _doubt.stats.totalUpvotes + 1 : _doubt.stats.totalUpvotes - 1,
        ),
      );
    });

    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/doubts', data: {'doubtId': _doubt.id, 'action': 'upvote'});
    } catch (e) {
      debugPrint("Upvote failed: $e");
    }
  }

  Future<void> _handleMarkSolved() async {
    setState(() {
      _doubt = _doubt.copyWith(isSolved: true, status: "solved");
    });
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/doubts', data: {'doubtId': _doubt.id, 'action': 'solve'});
    } catch (e) {
      debugPrint("Error marking solved: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to mark as solved")));
      }
      setState(() {
        _doubt = _doubt.copyWith(isSolved: false, status: "open");
      });
    }
  }

  void _handleDeleteDoubt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text("Delete doubt?", style: AppTypography.h3.copyWith(fontSize: 18)),
        content: Text("This can't be undone.", style: AppTypography.body.copyWith(color: AppColors.inkMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Cancel", style: AppTypography.label.copyWith(color: AppColors.inkMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final dio = ref.read(dioProvider);
                await dio.delete('/api/doubts', queryParameters: {'id': _doubt.id});
                if (mounted) {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/student/doubts');
                  }
                }
              } catch (e) {
                debugPrint("$e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete doubt")));
                }
              }
            },
            child: Text("Delete", style: AppTypography.label.copyWith(color: AppColors.coral)),
          ),
        ],
      ),
    );
  }

  void _handleDeleteReply(String replyId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text("Delete reply?", style: AppTypography.h3.copyWith(fontSize: 18)),
        content: Text("This can't be undone.", style: AppTypography.body.copyWith(color: AppColors.inkMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Cancel", style: AppTypography.label.copyWith(color: AppColors.inkMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() {
                _doubt = _doubt.copyWith(
                  stats: DoubtStats(
                    totalReplies: _doubt.stats.totalReplies - 1,
                    totalUpvotes: _doubt.stats.totalUpvotes,
                  ),
                  replies: _doubt.replies.where((r) => r.id != replyId).toList(),
                );
              });
              try {
                final dio = ref.read(dioProvider);
                await dio.delete('/api/doubts/reply', queryParameters: {'id': replyId});
              } catch (e) {
                debugPrint("$e");
              }
            },
            child: Text("Delete", style: AppTypography.label.copyWith(color: AppColors.coral)),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePickImage() async {
    setState(() => _uploadingImage = true);
    try {
      final uploadSvc = ref.read(uploadServiceProvider);
      final file = await uploadSvc.pickAndUploadImage();
      if (file != null) setState(() => _replyImage = file);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _handlePickPdf() async {
    setState(() => _uploadingPdf = true);
    try {
      final uploadSvc = ref.read(uploadServiceProvider);
      final file = await uploadSvc.pickAndUploadPDF();
      if (file != null) setState(() => _replyPdf = file);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      if (mounted) setState(() => _uploadingPdf = false);
    }
  }

  Future<void> _handlePostReply() async {
    if (_replyCtrl.text.trim().isEmpty && _replyImage == null && _replyPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please write something or attach a file")));
      return;
    }
    setState(() => _posting = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/api/doubts/reply', data: {
        'doubtId': _doubt.id,
        'content': _replyCtrl.text.trim(),
        'imageUrl': _replyImage?.url,
        'imageName': _replyImage?.name,
        'pdfUrl': _replyPdf?.url,
        'pdfName': _replyPdf?.name,
      });

      if (response.data['success'] == true && response.data['reply'] != null) {
        final rData = Map<String, dynamic>.from(response.data['reply'] as Map);
        rData['isMyReply'] = true;
        rData['hasUpvoted'] = false;
        final newReply = DoubtReply.fromJson(rData);

        setState(() {
          _doubt = _doubt.copyWith(
            stats: DoubtStats(
              totalReplies: _doubt.stats.totalReplies + 1,
              totalUpvotes: _doubt.stats.totalUpvotes,
            ),
            replies: [newReply, ..._doubt.replies],
          );
          _replyCtrl.clear();
          _replyImage = null;
          _replyPdf = null;
        });
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data['error'] ?? "Unknown error")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  bool get _canSend => !_posting && (_replyCtrl.text.trim().isNotEmpty || _replyImage != null || _replyPdf != null);

  @override
  Widget build(BuildContext context) {
    final sortedReplies = _sortReplies(_doubt.replies);

    return SafeBackScope(
      fallbackLocation: '/student/doubts',
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    _buildDoubtQuestionBlock(),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      "Replies (${_doubt.replies.length})",
                      style: AppTypography.label.copyWith(fontSize: 13.5, color: AppColors.ink),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (sortedReplies.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            "No replies yet. Be the first to help!",
                            style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.inkMuted),
                          ),
                        ),
                      )
                    else
                      ...sortedReplies.map((reply) => _buildReplyCard(reply)),
                  ],
                ),
              ),
              _buildReplyComposer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          AnimatedPressable(
            pressScale: 0.9,
            onPress: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/student/doubts');
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: AppRadius.smBorder,
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.arrowLeft, size: 18, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              "Doubt Details",
              style: AppTypography.h3.copyWith(fontSize: 16, color: AppColors.ink),
            ),
          ),
          if (_doubt.isMyDoubt)
            AnimatedPressable(
              pressScale: 0.9,
              onPress: _handleDeleteDoubt,
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Icon(LucideIcons.trash2, size: 18, color: AppColors.coral),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDoubtQuestionBlock() {
    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                name: _doubt.student.name,
                uri: _doubt.student.avatar,
                size: AppAvatarSize.md,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _doubt.student.name,
                    style: AppTypography.label.copyWith(fontSize: 14, color: AppColors.ink),
                  ),
                  Text(
                    "${_doubt.subject} • ${_formatTimeAgo(_doubt.createdAt)}",
                    style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _doubt.title,
            style: AppTypography.h3.copyWith(fontSize: 18, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            _doubt.description,
            style: AppTypography.body.copyWith(fontSize: 14, color: AppColors.inkMuted, height: 1.45),
          ),

          if (_doubt.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: ClipRRect(
                borderRadius: AppRadius.mdBorder,
                child: Image.network(
                  _doubt.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          if (_doubt.pdfUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: AnimatedPressable(
                pressScale: 0.96,
                onPress: () => launchUrl(Uri.parse(_doubt.pdfUrl!)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.coralTint,
                    borderRadius: AppRadius.smBorder,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.fileText, size: 14, color: AppColors.coral),
                      const SizedBox(width: 8),
                      Text(
                        _doubt.pdfName ?? "Download PDF",
                        style: AppTypography.label.copyWith(fontSize: 12.5, color: AppColors.coral),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              if (!_doubt.isSolved && _doubt.isMyDoubt) ...[
                AnimatedPressable(
                  pressScale: 0.95,
                  onPress: _handleMarkSolved,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: AppRadius.mdBorder,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.checkCircle2, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          "Mark as Solved",
                          style: AppTypography.label.copyWith(fontSize: 12, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              AppBadge(label: _doubt.priority, tone: _priorityTone(_doubt.priority)),
              if (_doubt.isSolved) ...[
                const SizedBox(width: 6),
                const AppBadge(label: "Solved", tone: AppBadgeTone.success),
              ],
              const Spacer(),
              AnimatedPressable(
                pressScale: 0.9,
                onPress: _handleUpvote,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.thumbsUp,
                      size: 15,
                      color: _doubt.hasUpvoted ? AppColors.indigo : AppColors.inkMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "${_doubt.stats.totalUpvotes}",
                      style: AppTypography.label.copyWith(
                        fontSize: 13,
                        color: _doubt.hasUpvoted ? AppColors.indigo : AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.eye, size: 14, color: AppColors.inkFaint),
                  const SizedBox(width: 5),
                  Text(
                    "${_doubt.views}",
                    style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyCard(DoubtReply reply) {
    final bool isTeacher = reply.user.role == "TEACHER";
    final Color bg = isTeacher
        ? AppColors.goldTint
        : reply.isPinned
            ? AppColors.goldTint
            : reply.isAccepted
                ? AppColors.mintTint
                : AppColors.surface;
    final Color border = isTeacher
        ? AppColors.gold.withValues(alpha: 0.35)
        : reply.isPinned
            ? AppColors.gold.withValues(alpha: 0.35)
            : reply.isAccepted
                ? AppColors.mint.withValues(alpha: 0.3)
                : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1.5),
        borderRadius: AppRadius.mdBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                name: reply.user.name,
                uri: reply.user.avatar,
                size: AppAvatarSize.sm,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          reply.user.name,
                          style: AppTypography.label.copyWith(fontSize: 13.5, color: AppColors.ink),
                        ),
                        if (isTeacher) ...[
                          const SizedBox(width: 6),
                          const AppBadge(label: "Teacher", tone: AppBadgeTone.gold),
                        ],
                        if (reply.isPinned)
                          Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(LucideIcons.pin, size: 11, color: AppColors.gold),
                          ),
                        if (reply.isAccepted)
                          Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(LucideIcons.checkCircle2, size: 11, color: AppColors.mint),
                          ),
                      ],
                    ),
                    Text(
                      _formatTimeAgo(reply.createdAt),
                      style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.inkFaint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reply.content,
            style: AppTypography.body.copyWith(fontSize: 13.5, color: AppColors.ink, height: 1.4),
          ),

          if (reply.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: ClipRRect(
                borderRadius: AppRadius.smBorder,
                child: Image.network(
                  reply.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          if (reply.pdfUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: AnimatedPressable(
                pressScale: 0.96,
                onPress: () => launchUrl(Uri.parse(reply.pdfUrl!)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.coralTint,
                    borderRadius: AppRadius.smBorder,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.fileText, size: 12, color: AppColors.coral),
                      const SizedBox(width: 6),
                      Text(
                        reply.pdfName ?? "Download PDF",
                        style: AppTypography.label.copyWith(fontSize: 11.5, color: AppColors.coral),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Row(
                children: [
                  Icon(LucideIcons.thumbsUp, size: 13, color: AppColors.inkMuted),
                  const SizedBox(width: 4),
                  Text(
                    "${reply.upvotes}",
                    style: AppTypography.label.copyWith(fontSize: 11.5, color: AppColors.inkMuted),
                  ),
                ],
              ),
              if (reply.isMyReply)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: AnimatedPressable(
                    pressScale: 0.9,
                    onPress: () => _handleDeleteReply(reply.id),
                    child: Text(
                      "Delete",
                      style: AppTypography.label.copyWith(fontSize: 11.5, color: AppColors.coral),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyComposer() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xF0162C36),
            Color(0xF50F2027),
          ],
        ),
        border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_replyImage != null || _replyPdf != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    if (_replyImage != null)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0x262EE6C5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x4D2EE6C5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.image, size: 12, color: Color(0xFF2EE6C5)),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 100),
                              child: Text(
                                _replyImage!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium.copyWith(fontSize: 11.5, color: const Color(0xFF2EE6C5)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => _replyImage = null),
                              child: const Icon(LucideIcons.x, size: 12, color: Color(0xFFFF6B6B)),
                            ),
                          ],
                        ),
                      ),
                    if (_replyPdf != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0x26FF6B6B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x4DFF6B6B)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.fileText, size: 12, color: Color(0xFFFF6B6B)),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 100),
                              child: Text(
                                _replyPdf!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium.copyWith(fontSize: 11.5, color: const Color(0xFFFF6B6B)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => _replyPdf = null),
                              child: const Icon(LucideIcons.x, size: 12, color: Color(0xFFFF6B6B)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            Text(
              "Your Response",
              style: AppTypography.label.copyWith(fontSize: 12, color: AppColors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x33FFFFFF), width: 1.0),
                    ),
                    child: TextField(
                      controller: _replyCtrl,
                      maxLines: 3,
                      minLines: 1,
                      cursorColor: const Color(0xFF2EE6C5),
                      style: AppTypography.body.copyWith(fontSize: 14, color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: "Type your answer here…",
                        hintStyle: AppTypography.body.copyWith(color: AppColors.inkFaint, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedPressable(
                  pressScale: 0.9,
                  onPress: _uploadingImage ? null : _handlePickImage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      border: Border.all(color: const Color(0x33FFFFFF), width: 1.0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: _uploadingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Color(0xFF2EE6C5), strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.image, size: 16, color: AppColors.inkMuted),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedPressable(
                  pressScale: 0.9,
                  onPress: _uploadingPdf ? null : _handlePickPdf,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      border: Border.all(color: const Color(0x33FFFFFF), width: 1.0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: _uploadingPdf
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Color(0xFFFF6B6B), strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.fileText, size: 16, color: AppColors.inkMuted),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedPressable(
                  pressScale: 0.9,
                  onPress: _canSend ? _handlePostReply : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _canSend ? const Color(0xFF2EE6C5) : const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _canSend ? const Color(0xFF2EE6C5) : const Color(0x33FFFFFF),
                        width: 1,
                      ),
                      boxShadow: _canSend
                          ? const [
                              BoxShadow(
                                color: Color(0x4D2EE6C5),
                                blurRadius: 12,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: _posting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: _canSend ? const Color(0xFF0F2027) : Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            LucideIcons.send,
                            size: 16,
                            color: _canSend ? const Color(0xFF0F2027) : AppColors.inkMuted,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
