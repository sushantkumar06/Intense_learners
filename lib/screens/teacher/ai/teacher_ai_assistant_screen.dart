import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/ai_assistant_message.dart';
import '../../../services/api_client.dart';
import '../../../services/cache_service.dart';
import '../../../services/upload_service.dart';
import '../../../theme/app_theme.dart';
import '../../../components/safe_back_scope.dart';
import '../../../components/ui/animated_pressable.dart';

class TeacherAIAssistantScreen extends ConsumerStatefulWidget {
  const TeacherAIAssistantScreen({super.key});

  @override
  ConsumerState<TeacherAIAssistantScreen> createState() =>
      _TeacherAIAssistantScreenState();
}

class _TeacherAIAssistantScreenState
    extends ConsumerState<TeacherAIAssistantScreen> {
  static const String _heroPhoto =
      "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=1200&q=80&auto=format&fit=crop";

  List<AIAssistantMessage> _messages = [];
  bool _loadingMessages = true;
  bool _sending = false;
  bool _uploadingImage = false;
  bool _uploadingFile = false;
  Map<String, String>? _uploadedFile;
  String? _copiedId;
  bool _showQuickActions = true;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _quickActions = [
    {
      "icon": LucideIcons.penTool,
      "label": "Create Lesson Plan",
      "prompt":
          "Create a detailed lesson plan for [subject] for [grade] students on the topic of [topic]",
      "color": AppColors.indigo,
      "tint": AppColors.indigoTint,
    },
    {
      "icon": LucideIcons.listChecks,
      "label": "Generate Quiz",
      "prompt":
          "Generate a 10-question multiple choice quiz on [topic] for [grade] level students",
      "color": AppColors.gold,
      "tint": AppColors.goldTint,
    },
    {
      "icon": LucideIcons.fileText,
      "label": "Design Assignment",
      "prompt":
          "Design a creative assignment on [topic] that encourages critical thinking for [grade] students",
      "color": AppColors.mint,
      "tint": AppColors.mintTint,
    },
    {
      "icon": LucideIcons.lightbulb,
      "label": "Teaching Strategy",
      "prompt":
          "Suggest innovative teaching strategies to make [topic] more engaging for students",
      "color": AppColors.coral,
      "tint": AppColors.coralTint,
    },
    {
      "icon": LucideIcons.calculator,
      "label": "Math Problem",
      "prompt":
          "Create practice problems with solutions for [math topic] at [grade] level",
      "color": AppColors.indigo,
      "tint": AppColors.indigoTint,
    },
    {
      "icon": LucideIcons.beaker,
      "label": "Science Experiment",
      "prompt":
          "Suggest a safe, engaging science experiment to demonstrate [concept] for [grade] students",
      "color": AppColors.mint,
      "tint": AppColors.mintTint,
    },
    {
      "icon": LucideIcons.globe,
      "label": "Explain Concept",
      "prompt":
          "Explain [complex topic] in simple terms suitable for [grade] level students",
      "color": AppColors.gold,
      "tint": AppColors.goldTint,
    },
    {
      "icon": LucideIcons.graduationCap,
      "label": "Study Guide",
      "prompt":
          "Create a comprehensive study guide for [topic] covering key concepts, definitions, and practice questions",
      "color": AppColors.coral,
      "tint": AppColors.coralTint,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCachedMessages();
    _fetchMessages();
  }

  void _loadCachedMessages() {
    final cached = CacheService.getSync("cached_teacher_ai_messages_v1");
    if (cached is List && cached.isNotEmpty) {
      final List<AIAssistantMessage> mapped = [];
      for (int i = 0; i < cached.length; i++) {
        final item = cached[i];
        if (item is Map) {
          mapped.add(AIAssistantMessage(
            id: (item['id'] ?? '').toString(),
            content: (item['content'] ?? '').toString(),
            fileUrl: item['fileUrl']?.toString(),
            fileName: item['fileName']?.toString(),
            fileType: item['fileType']?.toString(),
            fileSize: item['fileSize']?.toString(),
            createdAt: (item['createdAt'] ?? '').toString(),
            isAI: item['isAI'] == true || (i % 2 == 1),
          ));
        }
      }
      _messages = mapped;
      if (_messages.isNotEmpty) _showQuickActions = false;
      _loadingMessages = false;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final response =
          await ref.read(dioProvider).get("/api/teacher/ai-assistant");
      final data = response.data;
      if (data is Map && data['success'] == true && data['messages'] is List) {
        final List<AIAssistantMessage> mapped = [];
        final rawMessages = data['messages'] as List;
        CacheService.set("cached_teacher_ai_messages_v1", rawMessages);
        for (int i = 0; i < rawMessages.length; i++) {
          final item = rawMessages[i];
          if (item is Map) {
            mapped.add(AIAssistantMessage(
              id: (item['id'] ?? '').toString(),
              content: (item['content'] ?? '').toString(),
              fileUrl: item['fileUrl']?.toString(),
              fileName: item['fileName']?.toString(),
              fileType: item['fileType']?.toString(),
              fileSize: item['fileSize']?.toString(),
              createdAt: (item['createdAt'] ?? '').toString(),
              isAI: item['isAI'] == true || (i % 2 == 1),
            ));
          }
        }
        if (mounted) {
          setState(() {
            _messages = mapped;
            if (_messages.isNotEmpty) _showQuickActions = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching ai messages: $e");
    } finally {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  Future<void> _handlePickImage() async {
    setState(() => _uploadingImage = true);
    try {
      final uploadSvc = ref.read(uploadServiceProvider);
      final file = await uploadSvc.pickAndUploadImage();
      if (file != null && mounted) {
        setState(() {
          _uploadedFile = {
            "url": file.url,
            "name": file.name,
            "type": "image",
            "size": file.size,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _handlePickFile() async {
    setState(() => _uploadingFile = true);
    try {
      final uploadSvc = ref.read(uploadServiceProvider);
      final file = await uploadSvc.pickAndUploadFile();
      if (file != null && mounted) {
        setState(() {
          _uploadedFile = {
            "url": file.url,
            "name": file.name,
            "type": file.type ?? "pdf",
            "size": file.size,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _uploadingFile = false);
    }
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _uploadedFile == null) return;

    setState(() {
      _sending = true;
      _showQuickActions = false;
    });

    try {
      final history = _messages
          .map((m) =>
              {"role": m.isAI ? "assistant" : "user", "content": m.content})
          .toList();
      final payload = {
        "content": text,
        "fileUrl": _uploadedFile?['url'],
        "fileName": _uploadedFile?['name'],
        "fileType": _uploadedFile?['type'],
        "fileSize": _uploadedFile?['size'],
        "conversationHistory": history,
      };

      final response = await ref
          .read(dioProvider)
          .post("/api/teacher/ai-assistant", data: payload);
      final data = response.data;

      if (data['success'] == true) {
        setState(() {
          _messages.add(AIAssistantMessage.fromJson(
              {...data['userMessage'], "isAI": false}));
          _messages.add(AIAssistantMessage.fromJson(
              {...data['aiMessage'], "isAI": true}));
          _textController.clear();
          _uploadedFile = null;
        });
        _scrollToBottom();
      } else {
        if (mounted) {
          _showAlert("Error", data['error'] ?? "Failed to send message");
        }
      }
    } catch (e) {
      if (mounted) _showAlert("Error", "Something went wrong");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleClearChat() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          "Clear chat history?",
          style: AppTypography.h3.copyWith(color: AppColors.ink),
        ),
        content: Text(
          "This conversation will be cleared and cannot be recovered.",
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
              "Clear",
              style: AppTypography.label.copyWith(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response =
          await ref.read(dioProvider).delete("/api/teacher/ai-assistant");
      if (response.data['success'] == true) {
        setState(() {
          _messages.clear();
          _showQuickActions = true;
        });
      }
    } catch (e) {
      if (mounted) _showAlert("Error", "Failed to clear chat history");
    }
  }

  void _handleCopy(String text, String id) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copiedId = id);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _copiedId == id) setState(() => _copiedId = null);
    });
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

  @override
  Widget build(BuildContext context) {
    if (_loadingMessages) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.indigo,
                strokeWidth: 2.5,
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                "Loading EduGenius...",
                style: TextStyle(color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
      );
    }

    return SafeBackScope(
      fallbackLocation: '/teacher',
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildHeroHeader(),
              Expanded(
                child: (_messages.isEmpty && _showQuickActions)
                    ? _buildQuickActionsGrid()
                    : _buildChatList(),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.indigoDark,
        image: DecorationImage(
          image: const NetworkImage(_heroPhoto),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.35),
            BlendMode.darken,
          ),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xB80F2027),
              Color(0xD9203A43),
              Color(0xF20F2027),
            ],
          ),
        ),
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: topPadding + AppSpacing.sm,
          bottom: AppSpacing.md,
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: AppRadius.mdBorder,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.arrowLeft,
                  size: 18,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: AppRadius.mdBorder,
              ),
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.bot,
                size: 20,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "EduGenius AI",
                        style: AppTypography.label.copyWith(
                          color: AppColors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        LucideIcons.sparkles,
                        size: 13,
                        color: AppColors.gold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    "Your intelligent teaching assistant",
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white.withValues(alpha: 0.72),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedPressable(
              onPress: _fetchMessages,
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: AppRadius.smBorder,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.refreshCw,
                  size: 15,
                  color: AppColors.white,
                ),
              ),
            ),
            AnimatedPressable(
              onPress: _handleClearChat,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: AppRadius.smBorder,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.trash2,
                  size: 15,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Hero Welcome Avatar
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            alignment: Alignment.center,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2EE6C5), Color(0xFF1FCFB0)],
                        ),
                        borderRadius: AppRadius.xlBorder,
                        boxShadow: kAccentGlowShadow,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.bot,
                        size: 32,
                        color: AppColors.onIndigo,
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.paper,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.sparkles,
                          size: 11,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  "Welcome to EduGenius AI 👋",
                  style: AppTypography.h2.copyWith(
                    color: AppColors.ink,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 290),
                  child: Text(
                    "Try a quick action below or ask me anything about teaching, planning, and pedagogy.",
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkMuted,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2-column Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _quickActions.map((item) {
                  final color = item['color'] as Color;
                  final tint = item['tint'] as Color;

                  return SizedBox(
                    width: cardWidth,
                    child: AnimatedPressable(
                      pressScale: 0.96,
                      onPress: () {
                        setState(() {
                          _textController.text = item['prompt'] as String;
                          _showQuickActions = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.lgBorder,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: tint,
                                borderRadius: AppRadius.mdBorder,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                item['icon'] as IconData,
                                size: 16,
                                color: color,
                              ),
                            ),
                            Text(
                              item['label'] as String,
                              style: AppTypography.label.copyWith(
                                color: AppColors.ink,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['prompt'] as String,
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                color: AppColors.inkMuted,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Pro Tips Box
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.indigoTint,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(
                color: AppColors.indigo.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      size: 14,
                      color: AppColors.indigo,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      "Pro Tips",
                      style: AppTypography.label.copyWith(
                        fontSize: 12.5,
                        color: AppColors.indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...[
                  "Upload images or PDFs for help with visual content",
                  "Be specific with grade level and subject",
                  "Ask follow-up questions to refine content",
                ].map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(
                              LucideIcons.zap,
                              size: 11,
                              color: AppColors.indigo,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              tip,
                              style: AppTypography.caption.copyWith(
                                fontSize: 11.5,
                                color: AppColors.indigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _messages.length + (_sending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          // Thinking indicator
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.indigo,
                    borderRadius: AppRadius.smBorder,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    LucideIcons.bot,
                    size: 16,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: AppRadius.lgBorder,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          color: AppColors.indigo,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "EduGenius is thinking…",
                        style: AppTypography.caption.copyWith(
                          fontSize: 12,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final msg = _messages[index];
        final timeStr = msg.createdAt.isNotEmpty
            ? _formatTime(msg.createdAt)
            : "now";

        final maxBubbleWidth = MediaQuery.of(context).size.width * 0.78;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                msg.isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (msg.isAI) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.indigo,
                    borderRadius: AppRadius.smBorder,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    LucideIcons.bot,
                    size: 16,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: msg.isAI ? AppColors.surface : AppColors.indigo,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(msg.isAI ? 4 : 16),
                      topRight: const Radius.circular(16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: Radius.circular(msg.isAI ? 16 : 4),
                    ),
                    border: msg.isAI
                        ? Border.all(color: AppColors.border)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Sender & Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            msg.isAI ? "EduGenius AI" : "You",
                            style: AppTypography.label.copyWith(
                              fontSize: 11.5,
                              color: msg.isAI
                                  ? AppColors.ink
                                  : AppColors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              color: msg.isAI
                                  ? AppColors.inkMuted
                                  : AppColors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Attached File
                      if (msg.fileUrl != null && msg.fileUrl!.isNotEmpty)
                        AnimatedPressable(
                          pressScale: 0.97,
                          onPress: () => launchUrl(Uri.parse(msg.fileUrl!)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: msg.isAI
                                  ? AppColors.surfaceMuted
                                  : AppColors.white.withValues(alpha: 0.16),
                              borderRadius: AppRadius.mdBorder,
                              border: Border.all(
                                color: msg.isAI
                                    ? AppColors.border
                                    : AppColors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  msg.fileType == "image"
                                      ? LucideIcons.image
                                      : LucideIcons.fileText,
                                  size: 15,
                                  color: msg.isAI
                                      ? AppColors.indigo
                                      : AppColors.white,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.fileName ?? "File",
                                        style: AppTypography.label.copyWith(
                                          fontSize: 11,
                                          color: msg.isAI
                                              ? AppColors.ink
                                              : AppColors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        msg.fileSize ?? "",
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 9.5,
                                          color: msg.isAI
                                              ? AppColors.inkMuted
                                              : AppColors.white
                                                  .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  LucideIcons.download,
                                  size: 13,
                                  color: msg.isAI
                                      ? AppColors.indigo
                                      : AppColors.white,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Text Content
                      Text(
                        msg.content,
                        style: AppTypography.body.copyWith(
                          fontSize: 13.5,
                          height: 1.45,
                          color: msg.isAI ? AppColors.ink : AppColors.white,
                        ),
                      ),

                      // AI Copy Action
                      if (msg.isAI)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: AnimatedPressable(
                            pressScale: 0.93,
                            onPress: () => _handleCopy(msg.content, msg.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: AppRadius.smBorder,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _copiedId == msg.id
                                        ? LucideIcons.check
                                        : LucideIcons.copy,
                                    size: 11,
                                    color: _copiedId == msg.id
                                        ? AppColors.mint
                                        : AppColors.inkMuted,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _copiedId == msg.id ? "Copied!" : "Copy",
                                    style: AppTypography.label.copyWith(
                                      fontSize: 11,
                                      color: _copiedId == msg.id
                                        ? AppColors.mint
                                        : AppColors.inkMuted,
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
              ),
              if (!msg.isAI) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: AppRadius.smBorder,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    LucideIcons.user,
                    size: 16,
                    color: AppColors.white,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    final hasText = _textController.text.trim().isNotEmpty;
    final hasUpload = _uploadedFile != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
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
      child: Column(
        children: [
          if (hasUpload)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 8,
              ),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: const Color(0x262EE6C5),
                border: Border.all(
                  color: const Color(0x662EE6C5),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    _uploadedFile!['type'] == "image"
                        ? LucideIcons.image
                        : LucideIcons.fileText,
                    size: 16,
                    color: const Color(0xFF2EE6C5),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _uploadedFile!['name']!,
                          style: AppTypography.label.copyWith(
                            fontSize: 12,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _uploadedFile!['size']!,
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedPressable(
                    onPress: () => setState(() => _uploadedFile = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
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
                  constraints: const BoxConstraints(maxHeight: 90),
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x33FFFFFF), width: 1),
                  ),
                  child: TextField(
                    controller: _textController,
                    onChanged: (_) => setState(() {}),
                    enabled: !_sending,
                    maxLines: null,
                    cursorColor: const Color(0xFF2EE6C5),
                    style: AppTypography.body.copyWith(
                      fontSize: 13.5,
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: "Ask me anything about teaching…",
                      hintStyle: AppTypography.body.copyWith(
                        color: AppColors.inkMuted,
                        fontSize: 13.5,
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
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AnimatedPressable(
                onPress: (_sending || (!hasText && !hasUpload))
                    ? null
                    : _handleSend,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (hasText || hasUpload)
                        ? const Color(0xFF2EE6C5)
                        : const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (hasText || hasUpload)
                          ? const Color(0xFF2EE6C5)
                          : const Color(0x33FFFFFF),
                      width: 1,
                    ),
                    boxShadow: (hasText || hasUpload)
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
                            color: (hasText || hasUpload)
                                ? const Color(0xFF0F2027)
                                : AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          LucideIcons.send,
                          size: 17,
                          color: (hasText || hasUpload)
                              ? const Color(0xFF0F2027)
                              : AppColors.inkMuted,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Supports images (8MB) & PDFs (16MB)",
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              color: AppColors.inkMuted,
            ),
            textAlign: TextAlign.center,
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
}
