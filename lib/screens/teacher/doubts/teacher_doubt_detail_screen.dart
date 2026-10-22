import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/doubt.dart';
import '../../../services/api_client.dart';
import '../../../services/upload_service.dart';
import '../../../theme/app_theme.dart';
import '../../../components/safe_back_scope.dart';
import '../../../components/ui/app_badge.dart';
import '../../../components/ui/app_avatar.dart';
import '../../../components/ui/animated_pressable.dart';

class TeacherDoubtDetailScreen extends ConsumerStatefulWidget {
  final Doubt doubt;
  const TeacherDoubtDetailScreen({super.key, required this.doubt});

  @override
  ConsumerState<TeacherDoubtDetailScreen> createState() =>
      _TeacherDoubtDetailScreenState();
}

class _TeacherDoubtDetailScreenState
    extends ConsumerState<TeacherDoubtDetailScreen> {
  late Doubt _doubt;

  final TextEditingController _replyController = TextEditingController();
  Map<String, String>? _replyImage;
  Map<String, String>? _replyPdf;

  bool _uploadingImage = false;
  bool _uploadingPdf = false;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _doubt = widget.doubt;
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  String _formatTimeAgo(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inSeconds < 60) return "just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      if (diff.inDays < 7) return "${diff.inDays}d ago";
      if (diff.inDays < 28) return "${diff.inDays ~/ 7}w ago";
      return "${d.month}/${d.day}/${d.year}";
    } catch (_) {
      return '';
    }
  }

  AppBadgeTone _priorityTone(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return AppBadgeTone.success;
      case 'normal':
        return AppBadgeTone.brand;
      case 'high':
        return AppBadgeTone.gold;
      case 'urgent':
        return AppBadgeTone.danger;
      default:
        return AppBadgeTone.neutral;
    }
  }

  List<DoubtReply> _sortReplies(List<DoubtReply> replies) {
    final sorted = List<DoubtReply>.from(replies);
    sorted.sort((a, b) {
      if (a.user.role == 'TEACHER' && b.user.role != 'TEACHER') return -1;
      if (a.user.role != 'TEACHER' && b.user.role == 'TEACHER') return 1;
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      final tA = DateTime.tryParse(a.createdAt)?.millisecondsSinceEpoch ?? 0;
      final tB = DateTime.tryParse(b.createdAt)?.millisecondsSinceEpoch ?? 0;
      return tB.compareTo(tA);
    });
    return sorted;
  }

  Future<void> _handleMarkSolved() async {
    setState(() {
      _doubt = _doubt.copyWith(isSolved: true, status: 'solved');
    });
    try {
      await ref.read(dioProvider).patch(
        "/api/doubts",
        data: {"doubtId": _doubt.id, "action": "solve"},
      );
    } catch (e) {
      _showAlert("Error", "Failed to mark as solved");
      setState(() {
        _doubt = _doubt.copyWith(isSolved: false, status: 'open');
      });
    }
  }

  void _handleDeleteDoubt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          "Delete doubt?",
          style: AppTypography.h3.copyWith(color: AppColors.ink),
        ),
        content: Text(
          "This can't be undone.",
          style: AppTypography.body.copyWith(color: AppColors.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: AppTypography.label.copyWith(color: AppColors.inkMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(dioProvider)
                    .delete("/api/doubts?id=${_doubt.id}");
                if (mounted) {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/teacher/doubts');
                  }
                }
              } catch (e) {
                _showAlert("Error", "Failed to delete doubt");
              }
            },
            child: Text(
              "Delete",
              style: AppTypography.label.copyWith(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePinReply(String replyId) async {
    setState(() {
      _doubt = _doubt.copyWith(
        replies: _doubt.replies
            .map((r) => r.copyWith(isPinned: r.id == replyId))
            .toList(),
      );
    });
    try {
      await ref.read(dioProvider).patch(
        "/api/doubts",
        data: {"doubtId": _doubt.id, "action": "pin", "replyId": replyId},
      );
    } catch (e) {
      _showAlert("Error", "Failed to pin reply");
    }
  }

  Future<void> _handlePickImage() async {
    setState(() => _uploadingImage = true);
    try {
      final uploadSvc = ref.read(uploadServiceProvider);
      final file = await uploadSvc.pickAndUploadImage();
      if (file != null) {
        setState(() {
          _replyImage = {
            "url": file.url,
            "name": file.name,
          };
        });
      }
    } catch (e) {
      if (mounted) _showAlert("Error", "Image upload failed: $e");
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _handlePickPdf() async {
    setState(() => _uploadingPdf = true);
    try {
      final uploadSvc = ref.read(uploadServiceProvider);
      final file = await uploadSvc.pickAndUploadPDF();
      if (file != null) {
        setState(() {
          _replyPdf = {
            "url": file.url,
            "name": file.name,
          };
        });
      }
    } catch (e) {
      if (mounted) _showAlert("Error", "PDF upload failed: $e");
    } finally {
      if (mounted) setState(() => _uploadingPdf = false);
    }
  }

  Future<void> _handlePostReply() async {
    if (_replyController.text.trim().isEmpty &&
        _replyImage == null &&
        _replyPdf == null) {
      _showAlert("Empty reply", "Please write something or attach a file");
      return;
    }
    setState(() => _posting = true);
    try {
      final response = await ref.read(dioProvider).post("/api/doubts/reply", data: {
        "doubtId": _doubt.id,
        "content": _replyController.text.trim(),
        "imageUrl": _replyImage?['url'],
        "imageName": _replyImage?['name'],
        "pdfUrl": _replyPdf?['url'],
        "pdfName": _replyPdf?['name'],
      });
      final data = response.data;
      if (data['success'] == true) {
        final newReply =
            DoubtReply.fromJson(data['reply'] as Map<String, dynamic>);
        setState(() {
          _doubt = _doubt.copyWith(
            replies: [newReply, ..._doubt.replies],
            stats: DoubtStats(
              totalReplies: _doubt.stats.totalReplies + 1,
              totalUpvotes: _doubt.stats.totalUpvotes,
            ),
          );
          _replyController.clear();
          _replyImage = null;
          _replyPdf = null;
        });
      } else {
        _showAlert("Failed to post", data['error'] ?? "Unknown error");
      }
    } catch (e) {
      _showAlert("Error", "Something went wrong posting reply");
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _handleDeleteReply(String replyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          "Delete reply?",
          style: AppTypography.h3.copyWith(color: AppColors.ink),
        ),
        content: Text(
          "This can't be undone.",
          style: AppTypography.body.copyWith(color: AppColors.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "Cancel",
              style: AppTypography.label.copyWith(color: AppColors.inkMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "Delete",
              style: AppTypography.label.copyWith(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _doubt = _doubt.copyWith(
        replies: _doubt.replies.where((r) => r.id != replyId).toList(),
        stats: DoubtStats(
          totalReplies: _doubt.stats.totalReplies - 1,
          totalUpvotes: _doubt.stats.totalUpvotes,
        ),
      );
    });
    try {
      await ref.read(dioProvider).delete("/api/doubts/reply?id=$replyId");
    } catch (e) {
      debugPrint("Error deleting reply: $e");
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          title,
          style: AppTypography.h3.copyWith(color: AppColors.ink),
        ),
        content: Text(
          message,
          style: AppTypography.body.copyWith(color: AppColors.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "OK",
              style: AppTypography.label.copyWith(color: AppColors.indigo),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedReplies = _sortReplies(_doubt.replies);
    final canSend = !_posting &&
        (_replyController.text.trim().isNotEmpty ||
            _replyImage != null ||
            _replyPdf != null);

    return SafeBackScope(
      fallbackLocation: '/teacher/doubts',
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              // Top Nav Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedPressable(
                      pressScale: 0.9,
                      onPress: () => context.canPop()
                          ? context.pop()
                          : context.go('/teacher/doubts'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: AppRadius.smBorder,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        LucideIcons.arrowLeft,
                        size: 18,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Doubt Details & Reply",
                      style: AppTypography.h3.copyWith(
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  AnimatedPressable(
                    pressScale: 0.9,
                    onPress: _handleDeleteDoubt,
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: AppColors.coral,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Feed
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: sortedReplies.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildDoubtHeader();
                  }
                  final reply = sortedReplies[index - 1];
                  return _buildReplyCard(reply);
                },
              ),
            ),

            // Composer Area
            _buildComposer(canSend),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildDoubtHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
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
                    style: AppTypography.label.copyWith(
                      color: AppColors.ink,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "${_doubt.subject} • ${_formatTimeAgo(_doubt.createdAt)}",
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            _doubt.title,
            style: AppTypography.h3.copyWith(
              fontSize: 18,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _doubt.description,
            style: AppTypography.body.copyWith(
              fontSize: 14,
              color: AppColors.inkMuted,
              height: 1.45,
            ),
          ),

          if (_doubt.imageUrl != null && _doubt.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: AppRadius.mdBorder,
              child: Image.network(
                _doubt.imageUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 140,
                  color: AppColors.surfaceMuted,
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.image,
                    color: AppColors.inkFaint,
                  ),
                ),
              ),
            ),
          ],

          if (_doubt.pdfUrl != null && _doubt.pdfUrl!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AnimatedPressable(
              pressScale: 0.96,
              onPress: () => launchUrl(
                Uri.parse(_doubt.pdfUrl!),
                mode: LaunchMode.externalApplication,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.coralTint,
                  borderRadius: AppRadius.smBorder,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.fileText,
                      size: 14,
                      color: AppColors.coral,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _doubt.pdfName ?? "Download PDF",
                      style: AppTypography.label.copyWith(
                        color: AppColors.coral,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // Badges and Mark as Solved action
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!_doubt.isSolved)
                AnimatedPressable(
                  pressScale: 0.97,
                  onPress: _handleMarkSolved,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: AppRadius.mdBorder,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.mint.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.circleCheck,
                          size: 15,
                          color: AppColors.white,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          "Mark as Solved",
                          style: AppTypography.label.copyWith(
                            color: AppColors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              AppBadge(
                label: _doubt.priority,
                tone: _priorityTone(_doubt.priority),
              ),
              if (_doubt.isSolved)
                const AppBadge(
                  label: "Solved",
                  tone: AppBadgeTone.success,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            "Replies (${_doubt.replies.length})",
            style: AppTypography.label.copyWith(
              color: AppColors.ink,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyCard(DoubtReply reply) {
    final isTeacher = reply.user.role == "TEACHER";
    final bg = isTeacher
        ? AppColors.goldTint
        : reply.isPinned
            ? AppColors.goldTint
            : reply.isAccepted
                ? AppColors.mintTint
                : AppColors.surface;
    final borderColor = isTeacher
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
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          reply.user.name,
                          style: AppTypography.label.copyWith(
                            color: AppColors.ink,
                            fontSize: 13.5,
                          ),
                        ),
                        if (isTeacher)
                          const AppBadge(
                            label: "Teacher",
                            tone: AppBadgeTone.gold,
                          ),
                        if (reply.isPinned)
                          Icon(
                            LucideIcons.pin,
                            size: 11,
                            color: AppColors.gold,
                          ),
                        if (reply.isAccepted)
                          Icon(
                            LucideIcons.circleCheck,
                            size: 11,
                            color: AppColors.mint,
                          ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _formatTimeAgo(reply.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkFaint,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Text(
            reply.content,
            style: AppTypography.body.copyWith(
              color: AppColors.ink,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),

          if (reply.imageUrl != null && reply.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.smBorder,
              child: Image.network(
                reply.imageUrl!,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 100,
                  color: AppColors.surfaceMuted,
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.image,
                    color: AppColors.inkFaint,
                  ),
                ),
              ),
            ),
          ],

          if (reply.pdfUrl != null && reply.pdfUrl!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AnimatedPressable(
              pressScale: 0.96,
              onPress: () => launchUrl(
                Uri.parse(reply.pdfUrl!),
                mode: LaunchMode.externalApplication,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.coralTint,
                  borderRadius: AppRadius.smBorder,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.fileText,
                      size: 12,
                      color: AppColors.coral,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      reply.pdfName ?? "Download PDF",
                      style: AppTypography.label.copyWith(
                        color: AppColors.coral,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.thumbsUp,
                    size: 13,
                    color: AppColors.inkMuted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "${reply.upvotes}",
                    style: AppTypography.label.copyWith(
                      color: AppColors.inkMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
              if (!reply.isPinned) ...[
                const SizedBox(width: 16),
                AnimatedPressable(
                  pressScale: 0.9,
                  onPress: () => _handlePinReply(reply.id),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.pin,
                        size: 13,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Pin",
                        style: AppTypography.label.copyWith(
                          color: AppColors.gold,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              AnimatedPressable(
                pressScale: 0.9,
                onPress: () => _handleDeleteReply(reply.id),
                child: Text(
                  "Delete",
                  style: AppTypography.label.copyWith(
                    color: AppColors.coral,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(bool canSend) {
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
        border: Border(
          top: BorderSide(color: Color(0x33FFFFFF), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_replyImage != null || _replyPdf != null) ...[
              Row(
                children: [
                  if (_replyImage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0x262EE6C5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x4D2EE6C5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.image,
                            size: 12,
                            color: Color(0xFF2EE6C5),
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 100),
                            child: Text(
                              _replyImage!['name'] ?? 'Image',
                              style: AppTypography.caption.copyWith(
                                color: const Color(0xFF2EE6C5),
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedPressable(
                            pressScale: 0.9,
                            onPress: () => setState(() => _replyImage = null),
                            child: const Icon(
                              LucideIcons.x,
                              size: 12,
                              color: Color(0xFFFF6B6B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_replyPdf != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x26FF6B6B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x4DFF6B6B)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.fileText,
                            size: 12,
                            color: Color(0xFFFF6B6B),
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 100),
                            child: Text(
                              _replyPdf!['name'] ?? 'PDF Document',
                              style: AppTypography.caption.copyWith(
                                color: const Color(0xFFFF6B6B),
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedPressable(
                            pressScale: 0.9,
                            onPress: () => setState(() => _replyPdf = null),
                            child: const Icon(
                              LucideIcons.x,
                              size: 12,
                              color: Color(0xFFFF6B6B),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              "Your Response",
              style: AppTypography.label.copyWith(
                fontSize: 12,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 90),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x33FFFFFF), width: 1.0),
                    ),
                    child: TextField(
                      controller: _replyController,
                      onChanged: (_) => setState(() {}),
                      maxLines: null,
                      cursorColor: const Color(0xFF2EE6C5),
                      style: AppTypography.body.copyWith(
                        color: AppColors.ink,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: "Type your answer here…",
                        hintStyle: AppTypography.body.copyWith(
                          color: AppColors.inkFaint,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedPressable(
                  pressScale: 0.9,
                  onPress: _handlePickImage,
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2EE6C5),
                            ),
                          )
                        : const Icon(
                            LucideIcons.image,
                            size: 16,
                            color: AppColors.inkMuted,
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedPressable(
                  pressScale: 0.9,
                  onPress: _handlePickPdf,
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFF6B6B),
                            ),
                          )
                        : const Icon(
                            LucideIcons.fileText,
                            size: 16,
                            color: AppColors.inkMuted,
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedPressable(
                  pressScale: 0.9,
                  onPress: canSend ? _handlePostReply : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: canSend ? const Color(0xFF2EE6C5) : const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: canSend ? const Color(0xFF2EE6C5) : const Color(0x33FFFFFF),
                        width: 1,
                      ),
                      boxShadow: canSend
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
                              strokeWidth: 2,
                              color: canSend ? const Color(0xFF0F2027) : AppColors.white,
                            ),
                          )
                        : Icon(
                            LucideIcons.send,
                            size: 16,
                            color:
                                canSend ? const Color(0xFF0F2027) : AppColors.inkFaint,
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
