import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/teacher_chat_message.dart';
import '../../../services/api_client.dart';
import '../../../services/cache_service.dart';
import '../../../services/upload_service.dart';
import '../../../theme/app_theme.dart';
import '../../../components/safe_back_scope.dart';
import '../../../components/ui/animated_pressable.dart';
import '../../../components/ui/app_card.dart';
import '../../../components/ui/app_avatar.dart';
import '../../../components/ui/app_badge.dart';

class TeacherChatScreen extends ConsumerStatefulWidget {
  const TeacherChatScreen({super.key});

  @override
  ConsumerState<TeacherChatScreen> createState() => _TeacherChatScreenState();
}

class _TeacherChatScreenState extends ConsumerState<TeacherChatScreen> {
  List<TeacherChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _uploadingImage = false;
  bool _uploadingFile = false;

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _editingId;
  bool _savingEdit = false;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadCachedMessages();
    _fetchMessages();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 3000),
      (_) => _fetchMessages(),
    );
  }

  static final List<TeacherChatMessage> _defaultChatMessages = [
    TeacherChatMessage(
      id: "welcome-chat-1",
      content:
          "Welcome to the Teachers & Faculty Discussion Room. Use this space to coordinate academic schedules, lecture notes, syllabus pacing, and exam duties with other educators.",
      createdAt:
          DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
      isRead: true,
      readBy: [],
      sender: ChatSender(
        id: "system-1",
        name: "Academic Coordinator",
        avatar:
            "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80",
      ),
      isSelf: false,
    ),
  ];

  void _loadCachedMessages() {
    final cached = CacheService.getSync("cached_teacher_chat_v1");
    if (cached is List && cached.isNotEmpty) {
      final valid = cached
          .whereType<Map>()
          .map((e) => TeacherChatMessage.fromJson(e))
          .toList();
      if (valid.isNotEmpty) {
        _messages = valid;
        _loading = false;
        return;
      }
    }
    _messages = List.from(_defaultChatMessages);
    _loading = false;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _editController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      await ref
          .read(dioProvider)
          .patch("/api/teacher/chat", data: {"messageIds": ids});
    } catch (e) {
      debugPrint("Error marking read: $e");
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final response =
          await ref.read(dioProvider).get("/api/teacher/chat?limit=100");
      if (response.data is Map && response.data['success'] == true) {
        final rawMessages = response.data['messages'];
        if (rawMessages is List) {
          final msgData = rawMessages.whereType<Map>().toList();
          if (msgData.isNotEmpty) {
            CacheService.set("cached_teacher_chat_v1", msgData);
            final next =
                msgData.map((e) => TeacherChatMessage.fromJson(e)).toList();

            final prevLength = _messages.length;
            if (mounted) {
              setState(() {
                _messages = next;
                _loading = false;
              });
            }

            if (next.length != prevLength) {
              final unread = next
                  .where((m) => !m.isSelf && !m.isRead)
                  .map((m) => m.id)
                  .toList();
              if (unread.isNotEmpty) {
                _markAsRead(unread);
              }
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching messages: $e");
    } finally {
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage({
    String? fileUrl,
    String? fileName,
    String? fileType,
    String? fileSize,
  }) async {
    final text = _textController.text.trim();
    if (text.isEmpty && fileUrl == null) return;

    setState(() => _sending = true);
    try {
      final response =
          await ref.read(dioProvider).post("/api/teacher/chat", data: {
        "content": text,
        "fileUrl": fileUrl,
        "fileName": fileName,
        "fileType": fileType,
        "fileSize": fileSize,
      });

      if (response.data['success'] == true) {
        final msg = TeacherChatMessage.fromJson(response.data['message']);
        setState(() {
          _messages.add(msg);
          _textController.clear();
        });
        _scrollToBottom();
      } else {
        _showAlert("Error", "Failed to send message");
      }
    } catch (e) {
      _showAlert("Error", "Something went wrong");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handlePickImage() async {
    setState(() => _uploadingImage = true);
    try {
      final uploadSvc = ref.read(uploadServiceProvider);
      final file = await uploadSvc.pickAndUploadImage();
      if (file != null) {
        await _sendMessage(
          fileUrl: file.url,
          fileName: file.name,
          fileType: "image",
          fileSize: file.size,
        );
      }
    } catch (e) {
      if (mounted) _showAlert("Error", "Image upload failed: $e");
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _handlePickFile() async {
    setState(() => _uploadingFile = true);
    try {
      final uploadSvc = ref.read(uploadServiceProvider);
      final file = await uploadSvc.pickAndUploadFile();
      if (file != null) {
        await _sendMessage(
          fileUrl: file.url,
          fileName: file.name,
          fileType: file.type ?? "file",
          fileSize: file.size,
        );
      }
    } catch (e) {
      if (mounted) _showAlert("Error", "File upload failed: $e");
    } finally {
      if (mounted) setState(() => _uploadingFile = false);
    }
  }

  void _startEdit(TeacherChatMessage msg) {
    setState(() {
      _editingId = msg.id;
      _editController.text = msg.content;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _editController.clear();
    });
  }

  Future<void> _saveEdit() async {
    final text = _editController.text.trim();
    if (_editingId == null || text.isEmpty) return;

    setState(() => _savingEdit = true);
    try {
      final response =
          await ref.read(dioProvider).put("/api/teacher/chat", data: {
        "messageId": _editingId,
        "content": text,
      });

      if (response.data['success'] == true) {
        setState(() {
          _messages = _messages.map((m) {
            if (m.id == _editingId) {
              return TeacherChatMessage(
                id: m.id,
                content: text,
                fileUrl: m.fileUrl,
                fileName: m.fileName,
                fileType: m.fileType,
                fileSize: m.fileSize,
                isRead: m.isRead,
                readBy: m.readBy,
                createdAt: m.createdAt,
                updatedAt: DateTime.now().toIso8601String(),
                sender: m.sender,
                isSelf: m.isSelf,
              );
            }
            return m;
          }).toList();
        });
        _cancelEdit();
      } else {
        _showAlert("Error", "Failed to update message");
      }
    } catch (e) {
      _showAlert("Error", "Failed to update message");
    } finally {
      if (mounted) setState(() => _savingEdit = false);
    }
  }

  Future<void> _deleteMessage(String id) async {
    setState(() => _messages.removeWhere((m) => m.id == id));
    try {
      await ref.read(dioProvider).delete("/api/teacher/chat?id=$id");
    } catch (e) {
      _fetchMessages();
    }
  }

  void _handleLongPress(TeacherChatMessage msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.raised,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (msg.isSelf && msg.content.isNotEmpty)
                ListTile(
                  leading: Icon(
                    LucideIcons.pencil,
                    size: 18,
                    color: AppColors.ink,
                  ),
                  title: Text(
                    "Edit Message",
                    style:
                        AppTypography.label.copyWith(color: AppColors.ink),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _startEdit(msg);
                  },
                ),
              if (msg.isSelf && msg.content.isNotEmpty)
                Divider(height: 1, color: AppColors.border),
              if (msg.isSelf)
                ListTile(
                  leading: Icon(
                    LucideIcons.trash2,
                    size: 18,
                    color: AppColors.coral,
                  ),
                  title: Text(
                    "Delete Message",
                    style:
                        AppTypography.label.copyWith(color: AppColors.coral),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDeleteConfirm(msg.id);
                  },
                ),
              if (msg.isSelf)
                Divider(height: 1, color: AppColors.border),
              ListTile(
                leading: Icon(
                  LucideIcons.x,
                  size: 18,
                  color: AppColors.inkMuted,
                ),
                title: Text(
                  "Cancel",
                  style:
                      AppTypography.label.copyWith(color: AppColors.inkMuted),
                ),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          "Delete message?",
          style: AppTypography.h3.copyWith(color: AppColors.ink),
        ),
        content: Text(
          "This message will be permanently removed for everyone.",
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
            onPressed: () {
              Navigator.pop(ctx);
              _deleteMessage(id);
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

  void _showAlert(String title, String message) {
    if (!mounted) return;
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

  String _formatTime(String iso) {
    try {
      final date = DateTime.parse(iso).toLocal();
      int h = date.hour;
      final m = date.minute.toString().padLeft(2, '0');
      final ampm = h >= 12 ? 'PM' : 'AM';
      if (h == 0) {
        h = 12;
      } else if (h > 12) {
        h -= 12;
      }
      return '$h:$m $ampm';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeBackScope(
      fallbackLocation: '/teacher',
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.indigo,
                          strokeWidth: 2.5,
                        ),
                      )
                    : _messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final wasEdited = msg.updatedAt != null &&
                                  msg.updatedAt != msg.createdAt;
                              final isEditing = _editingId == msg.id;

                              if (msg.isSelf) {
                                return _buildSelfBubble(msg, isEditing, wasEdited);
                              } else {
                                return _buildOtherBubble(msg, wasEdited);
                              }
                            },
                          ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          AnimatedPressable(
            onPress: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/teacher');
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.arrowLeft,
                size: 18,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.indigoTint,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(
                color: AppColors.indigo.withValues(alpha: 0.15),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              LucideIcons.users,
              size: 20,
              color: AppColors.indigo,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Faculty Lounge",
                  style: AppTypography.label.copyWith(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Container(
                      width: 6.5,
                      height: 6.5,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "${_messages.length} messages",
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const AppBadge(
            label: "Teacher Room",
            tone: AppBadgeTone.brand,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.indigoTint,
                  borderRadius: AppRadius.lgBorder,
                ),
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.messageSquare,
                  size: 28,
                  color: AppColors.indigo,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "No messages yet",
                style: AppTypography.h3.copyWith(
                  color: AppColors.ink,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Collaborate with your fellow teachers, discuss study materials, and coordinate schedules.",
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelfBubble(
    TeacherChatMessage msg,
    bool isEditing,
    bool wasEdited,
  ) {
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.78;

    return Container(
      alignment: Alignment.centerRight,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (msg.fileUrl != null)
              _FileBubble(
                fileUrl: msg.fileUrl!,
                fileName: msg.fileName,
                fileType: msg.fileType,
                fileSize: msg.fileSize,
                isSelf: true,
              ),
            if (isEditing)
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: const Color(0x2E162C36),
                  border: Border.all(color: const Color(0x662EE6C5), width: 1.0),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _editController,
                      autofocus: true,
                      maxLines: null,
                      cursorColor: const Color(0xFF2EE6C5),
                      style: AppTypography.body.copyWith(
                        color: AppColors.ink,
                        fontSize: 13.5,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedPressable(
                          onPress: _savingEdit ? null : _cancelEdit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: AppRadius.smBorder,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              "Cancel",
                              style: AppTypography.label.copyWith(
                                fontSize: 11.5,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        AnimatedPressable(
                          onPress: (_savingEdit ||
                                  _editController.text.trim().isEmpty)
                              ? null
                              : _saveEdit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.indigo,
                              borderRadius: AppRadius.smBorder,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_savingEdit)
                                  const SizedBox(
                                    width: 11,
                                    height: 11,
                                    child: CircularProgressIndicator(
                                      color: AppColors.white,
                                      strokeWidth: 1.5,
                                    ),
                                  )
                                else
                                  const Icon(
                                    LucideIcons.check,
                                    size: 12,
                                    color: AppColors.white,
                                  ),
                                const SizedBox(width: 4),
                                Text(
                                  "Save",
                                  style: AppTypography.label.copyWith(
                                    fontSize: 11.5,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else if (msg.content.isNotEmpty)
              GestureDetector(
                onLongPress: () => _handleLongPress(msg),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.indigo,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        msg.content,
                        style: AppTypography.body.copyWith(
                          color: AppColors.white,
                          fontSize: 14,
                        ),
                      ),
                      if (wasEdited) ...[
                        const SizedBox(height: 2),
                        Text(
                          "edited",
                          style: AppTypography.caption.copyWith(
                            color: AppColors.white.withValues(alpha: 0.65),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(msg.createdAt),
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? LucideIcons.checkCheck : LucideIcons.check,
                    size: 12,
                    color: msg.isRead ? AppColors.mint : AppColors.inkMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherBubble(TeacherChatMessage msg, bool wasEdited) {
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.78;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            uri: msg.sender.avatar,
            name: msg.sender.name ?? "Teacher",
            size: AppAvatarSize.sm,
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 3),
                  child: Text(
                    msg.sender.name ?? "Teacher",
                    style: AppTypography.label.copyWith(
                      fontSize: 11.5,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
                if (msg.fileUrl != null)
                  _FileBubble(
                    fileUrl: msg.fileUrl!,
                    fileName: msg.fileName,
                    fileType: msg.fileType,
                    fileSize: msg.fileSize,
                    isSelf: false,
                  ),
                if (msg.content.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.content,
                          style: AppTypography.body.copyWith(
                            color: AppColors.ink,
                            fontSize: 14,
                          ),
                        ),
                        if (wasEdited) ...[
                          const SizedBox(height: 2),
                          Text(
                            "edited",
                            style: AppTypography.caption.copyWith(
                              color: AppColors.inkMuted,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    _formatTime(msg.createdAt),
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.inkMuted,
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

  Widget _buildBottomBar() {
    final hasText = _textController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 4,
      ),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedPressable(
              onPress: _uploadingFile ? null : _handlePickFile,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x33FFFFFF), width: 1),
                ),
                alignment: Alignment.center,
                child: _uploadingFile
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Color(0xFF2EE6C5),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        LucideIcons.paperclip,
                        size: 18,
                        color: AppColors.inkMuted,
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            AnimatedPressable(
              onPress: _uploadingImage ? null : _handlePickImage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x33FFFFFF), width: 1),
                ),
                alignment: Alignment.center,
                child: _uploadingImage
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Color(0xFF2EE6C5),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        LucideIcons.image,
                        size: 18,
                        color: AppColors.inkMuted,
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 100),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x33FFFFFF), width: 1),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  cursorColor: const Color(0xFF2EE6C5),
                  style: AppTypography.body.copyWith(
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.inkMuted,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            AnimatedPressable(
              onPress: (_sending || !hasText) ? null : () => _sendMessage(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasText ? const Color(0xFF2EE6C5) : const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasText ? const Color(0xFF2EE6C5) : const Color(0x33FFFFFF),
                    width: 1,
                  ),
                  boxShadow: hasText
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
                child: _sending
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: hasText ? const Color(0xFF0F2027) : AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        LucideIcons.send,
                        size: 17,
                        color: hasText ? const Color(0xFF0F2027) : AppColors.inkMuted,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileBubble extends StatelessWidget {
  final String fileUrl;
  final String? fileName;
  final String? fileType;
  final String? fileSize;
  final bool isSelf;

  const _FileBubble({
    required this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileSize,
    required this.isSelf,
  });

  @override
  Widget build(BuildContext context) {
    if (fileType == 'image') {
      return GestureDetector(
        onTap: () async {
          final url = Uri.parse(fileUrl);
          if (await canLaunchUrl(url)) await launchUrl(url);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdBorder,
            border: Border.all(
              color: isSelf
                  ? AppColors.white.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            fileUrl,
            width: 220,
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 220,
              height: 120,
              color: AppColors.surfaceMuted,
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.image,
                size: 28,
                color: AppColors.inkMuted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: isSelf
            ? AppColors.white.withValues(alpha: 0.15)
            : AppColors.surface,
        border: Border.all(
          color: isSelf
              ? AppColors.white.withValues(alpha: 0.35)
              : AppColors.border,
        ),
        borderRadius: AppRadius.mdBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelf
                  ? AppColors.white.withValues(alpha: 0.2)
                  : AppColors.indigoTint,
              borderRadius: AppRadius.smBorder,
            ),
            alignment: Alignment.center,
            child: Icon(
              LucideIcons.fileText,
              size: 18,
              color: isSelf ? AppColors.white : AppColors.indigo,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName ?? "Attachment.pdf",
                  style: AppTypography.label.copyWith(
                    fontSize: 12,
                    color: isSelf ? AppColors.white : AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  fileSize ?? "Document",
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: isSelf
                        ? AppColors.white.withValues(alpha: 0.75)
                        : AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AnimatedPressable(
            onPress: () async {
              final url = Uri.parse(fileUrl);
              if (await canLaunchUrl(url)) await launchUrl(url);
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isSelf
                    ? AppColors.white.withValues(alpha: 0.25)
                    : AppColors.indigoTint,
                borderRadius: AppRadius.smBorder,
              ),
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.download,
                size: 14,
                color: isSelf ? AppColors.white : AppColors.indigo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
