import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../../services/api_client.dart';

class ChatMessage {
  final String role;
  final String content;

  const ChatMessage({required this.role, required this.content});
}

class ChatWidget extends ConsumerStatefulWidget {
  final bool visible;
  final VoidCallback onClose;

  const ChatWidget({super.key, required this.visible, required this.onClose});

  @override
  ConsumerState<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends ConsumerState<ChatWidget> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final String _sessionId;
  List<ChatMessage> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _sessionId =
        "${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999999).toRadixString(36)}";
    _messages = [
      const ChatMessage(
        role: "assistant",
        content:
            "Hi! 👋 I'm your AI assistant. How can I help you today? I can answer questions about our courses, pricing, enrollment, or anything else about Intense Learners!",
      ),
    ];
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _loading) return;

    _inputController.clear();
    setState(() {
      _messages.add(ChatMessage(role: "user", content: text));
      _loading = true;
    });

    _scrollToBottom();

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        "/api/chat",
        data: {"message": text, "sessionId": _sessionId},
      );

      setState(() {
        _messages.add(
          ChatMessage(
            role: "assistant",
            content: response.data['response'] ?? '',
          ),
        );
      });
    } on DioException catch (e) {
      final err =
          e.response?.data?['response'] as String? ??
          "Sorry, I encountered an error. Please try again or contact support directly.";
      setState(() {
        _messages.add(ChatMessage(role: "assistant", content: err));
      });
    } catch (e) {
      setState(() {
        _messages.add(
          const ChatMessage(
            role: "assistant",
            content:
                "Sorry, I encountered an error. Please try again or contact support directly.",
          ),
        );
      });
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: widget.visible
              ? Colors.black.withValues(alpha: 0.5)
              : Colors.transparent,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            offset: widget.visible ? Offset.zero : const Offset(0, 1),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: GestureDetector(
                onTap: widget.onClose,
                child: Column(
                  children: [
                    Expanded(
                      flex: 2, // Top 20% empty space
                      child: Container(color: Colors.transparent),
                    ),
                    Expanded(
                      flex: 8, // Bottom 80% chat interface
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: kGlassModalFillGradient,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                            border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
                            boxShadow: kGlassCardShadow,
                          ),
                          child: Column(
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0x1FFFFFFF),
                                  border: Border(bottom: BorderSide(color: Color(0x1FFFFFFF))),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0x262EE6C5),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0x4D2EE6C5), width: 1),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            LucideIcons.bot,
                                            size: 20,
                                            color: Color(0xFF2EE6C5),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "AI Assistant",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF2EE6C5),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  "Online",
                                                  style: TextStyle(
                                                    color: AppColors.inkMuted,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: widget.onClose,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          LucideIcons.x,
                                          size: 18,
                                          color: AppColors.inkMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Messages
                              Expanded(
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount:
                                      _messages.length + (_loading ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _messages.length) {
                                      // Loading indicator
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: const BoxDecoration(
                                                color: Color(0x262EE6C5),
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                LucideIcons.bot,
                                                size: 14,
                                                color: Color(0xFF2EE6C5),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0x14FFFFFF),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: const Color(0x26FFFFFF), width: 1),
                                              ),
                                              child: const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  color: Color(0xFF2EE6C5),
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    final msg = _messages[index];
                                    final isUser = msg.role == "user";

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        mainAxisAlignment: isUser
                                            ? MainAxisAlignment.end
                                            : MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          if (!isUser) ...[
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: const BoxDecoration(
                                                color: Color(0x262EE6C5),
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                LucideIcons.bot,
                                                size: 14,
                                                color: Color(0xFF2EE6C5),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Flexible(
                                            child: Container(
                                              constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context).size.width * 0.78,
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isUser
                                                    ? const Color(0xFF2EE6C5)
                                                    : const Color(0x14FFFFFF),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: isUser ? Colors.transparent : const Color(0x26FFFFFF),
                                                  width: 1,
                                                ),
                                                boxShadow: isUser ? kAccentGlowShadow : null,
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (!isUser) ...[
                                                    const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          LucideIcons.sparkles,
                                                          size: 11,
                                                          color: Color(0xFF2EE6C5),
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          "AI Assistant",
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w600,
                                                            color: Color(0xFF2EE6C5),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                  ],
                                                  Text(
                                                    msg.content,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: isUser ? const Color(0xFF0F2027) : Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Input Area
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Color(0x1FFFFFFF)),
                                  ),
                                ),
                                child: SafeArea(
                                  top: false,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: const Color(0x14FFFFFF),
                                            border: Border.all(
                                              color: const Color(0x26FFFFFF),
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: TextField(
                                            controller: _inputController,
                                            enabled: !_loading,
                                            cursorColor: const Color(0xFF2EE6C5),
                                            decoration: const InputDecoration(
                                              hintText: "Ask me anything...",
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              filled: false,
                                              contentPadding: EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 12,
                                              ),
                                              hintStyle: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.inkFaint,
                                              ),
                                              isDense: true,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                            onSubmitted: (_) => _handleSend(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: _handleSend,
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: _loading
                                                ? const Color(0xFF2EE6C5).withValues(alpha: 0.35)
                                                : const Color(0xFF2EE6C5),
                                            borderRadius: BorderRadius.circular(14),
                                            boxShadow: _loading ? null : kAccentGlowShadow,
                                          ),
                                          alignment: Alignment.center,
                                          child: _loading
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    color: Color(0xFF0F2027),
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Icon(
                                                  LucideIcons.send,
                                                  size: 16,
                                                  color: Color(0xFF0F2027),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Text(
                                  "AI can make mistakes. Verify important info.",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.inkFaint,
                                  ),
                                  textAlign: TextAlign.center,
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
          ),
        ),
      ),
    );
  }
}
