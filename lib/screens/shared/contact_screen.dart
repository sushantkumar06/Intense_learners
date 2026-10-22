import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../components/ui/ui.dart';
import '../../components/contact/chat_widget.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _subjectController;
  late final TextEditingController _messageController;

  String _category = "general";
  bool _sending = false;
  bool _sent = false;
  bool _chatOpen = false;
  int? _openFaq;

  final List<Map<String, String>> _categories = [
    {"value": "general", "label": "General Inquiry"},
    {"value": "technical", "label": "Technical Support"},
    {"value": "billing", "label": "Billing & Payments"},
    {"value": "feature", "label": "Feature Request"},
    {"value": "bug", "label": "Report a Bug"},
    {"value": "feedback", "label": "Feedback"},
    {"value": "partnership", "label": "Partnership"},
    {"value": "teaching", "label": "Become a Teacher"},
  ];

  final List<Map<String, dynamic>> _contactInfo = [
    {
      "icon": LucideIcons.mail,
      "title": "Email Us",
      "value": "pandeyranu087@gmail.com",
      "desc": "Send us an email anytime",
      "url": "mailto:pandeyranu087@gmail.com",
    },
    {
      "icon": LucideIcons.phone,
      "title": "Call Us",
      "value": "+91 91186 10664",
      "desc": "Mon–Fri, 9am to 6pm",
      "url": "tel:+919118610664",
    },
    {
      "icon": LucideIcons.mapPin,
      "title": "Visit Us",
      "value": "Hanuman Mandir, Adarsh Nagar, Delhi",
      "desc": "Come say hello",
      "url": "https://maps.app.goo.gl/ByExkEywvFAxG84c9?g_st=aw",
    },
    {
      "icon": LucideIcons.clock,
      "title": "Working Hours",
      "value": "8:00 AM – 10:00 PM",
      "desc": "All days",
      "url": null,
    },
  ];

  final List<Map<String, String>> _faqs = [
    {
      "q": "How quickly do you respond?",
      "a": "We aim to respond to all inquiries within 24 hours during business days.",
    },
    {
      "q": "Can I schedule a demo call?",
      "a": "Yes! Mention it in your message and we'll arrange a convenient time.",
    },
    {
      "q": "Do you offer phone support?",
      "a": "Phone support is available for all users. Contact us to learn more.",
    },
  ];

  final List<Map<String, dynamic>> _socialLinks = [
    {
      "icon": LucideIcons.globe,
      "url": "https://youtube.com/@intense_learners?si=PKpm1w_PnuAImiYG",
    },
    {
      "icon": LucideIcons.globe,
      "url": "https://www.instagram.com/intense_learners?igsh=MTVtNTV2Znd6cGVrZQ==",
    },
    {
      "icon": LucideIcons.globe,
      "url": "https://www.facebook.com/share/1E77DTHG5w/",
    },
    {
      "icon": LucideIcons.mapPin,
      "url": "https://maps.app.goo.gl/ByExkEywvFAxG84c9?g_st=aw",
    },
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?['name']?.toString() ?? "");
    _emailController = TextEditingController(text: user?['email']?.toString() ?? "");
    _subjectController = TextEditingController();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.coral,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (name.isEmpty || email.isEmpty || subject.isEmpty || message.isEmpty) {
      _showError("Please fill in all required fields");
      return;
    }
    final emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    if (!emailRegex.hasMatch(email)) {
      _showError("Please enter a valid email address");
      return;
    }

    setState(() => _sending = true);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post("/api/contact", data: {
        "name": name,
        "email": email,
        "subject": subject,
        "category": _category,
        "message": message,
      });

      if (response.data['success'] != false) {
        setState(() {
          _sent = true;
          _subjectController.clear();
          _messageController.clear();
          _category = "general";
        });
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _sent = false);
        });
      } else {
        _showError(response.data['error'] ?? "Failed to send message");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        _showError(e.response?.data?['error'] ?? "Please try again later");
      } else {
        _showError(
          e.response?.data?['error'] ??
              "Failed to send message. Please try again or email us directly.",
        );
      }
    } catch (e) {
      _showError("Failed to send message. Please try again or email us directly.");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null) return;
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    bool isEmail = false,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
            minLines: minLines,
            maxLines: maxLines,
            cursorColor: const Color(0xFF2EE6C5),
            style: AppTypography.body.copyWith(fontSize: 14, color: AppColors.ink),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0x14FFFFFF),
              hintText: placeholder,
              hintStyle: AppTypography.body.copyWith(color: AppColors.inkFaint, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0x26FFFFFF), width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0x992EE6C5), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_chatOpen) {
          setState(() => _chatOpen = false);
          return;
        }
        context.go('/student/dashboard');
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Top Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        if (context.canPop()) ...[
                          AnimatedPressable(
                            pressScale: 0.9,
                            onPress: () => context.canPop()
                                ? context.pop()
                                : context.go('/student/dashboard'),
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
                          const SizedBox(width: 12),
                        ],
                      Text(
                        "Contact Us",
                        style: AppTypography.h3.copyWith(fontSize: 16, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                    child: Column(
                      children: [
                        // Centered Hero Header
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.indigoTint,
                                  borderRadius: AppRadius.pillBorder,
                                ),
                                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.bot, size: 12, color: AppColors.indigo),
                                    const SizedBox(width: 6),
                                    Text(
                                      "24/7 AI Support Available",
                                      style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                        color: AppColors.indigo,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "Let's Connect",
                                style: AppTypography.h2.copyWith(fontSize: 22, color: AppColors.ink),
                              ),
                              const SizedBox(height: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 300),
                                child: Text(
                                  "Have questions? We're here to help. Send us a message or chat with our AI assistant.",
                                  textAlign: TextAlign.center,
                                  style: AppTypography.body.copyWith(
                                    fontSize: 13,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Contact info - Horizontal scroll cards
                        SizedBox(
                          height: 124,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _contactInfo.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final info = _contactInfo[index];
                              final isClickable = info['url'] != null;
                              return AnimatedPressable(
                                pressScale: 0.96,
                                onPress: isClickable ? () => _launchUrl(info['url'] as String?) : null,
                                child: Container(
                                  width: 154,
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
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: AppColors.indigoTint,
                                          borderRadius: AppRadius.smBorder,
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(info['icon'] as IconData, size: 16, color: AppColors.indigo),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        info['title'] as String,
                                        style: AppTypography.label.copyWith(fontSize: 12, color: AppColors.ink),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        info['value'] as String,
                                        style: AppTypography.caption.copyWith(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                          color: AppColors.inkMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        info['desc'] as String,
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 10,
                                          color: AppColors.inkFaint,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Message Form Card
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.lgBorder,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Send Us a Message",
                                    style: AppTypography.h3.copyWith(fontSize: 15.5, color: AppColors.ink),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: AppColors.mint,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        "Online",
                                        style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              if (_sent) ...[
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: AppColors.mintTint,
                                    borderRadius: AppRadius.mdBorder,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.checkCircle2, size: 18, color: AppColors.mint),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Message sent successfully ✨",
                                              style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.mint),
                                            ),
                                            Text(
                                              "We'll get back to you within 24 hours.",
                                              style: AppTypography.caption.copyWith(color: AppColors.mint),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              _buildField(
                                label: "Your Name *",
                                controller: _nameController,
                                placeholder: "Your full name",
                              ),
                              _buildField(
                                label: "Email Address *",
                                controller: _emailController,
                                placeholder: "you@example.com",
                                isEmail: true,
                              ),

                              // Category selector
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Category *",
                                      style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 36,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _categories.length,
                                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                                        itemBuilder: (context, index) {
                                          final c = _categories[index];
                                          final active = _category == c['value'];
                                          return AnimatedPressable(
                                            pressScale: 0.95,
                                            onPress: () => setState(() => _category = c['value']!),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: active ? AppColors.indigo : AppColors.surfaceMuted,
                                                borderRadius: AppRadius.mdBorder,
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                c['label']!,
                                                style: AppTypography.label.copyWith(
                                                  fontSize: 11.5,
                                                  color: active ? Colors.white : AppColors.inkMuted,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              _buildField(
                                label: "Subject *",
                                controller: _subjectController,
                                placeholder: "How can we help you?",
                              ),
                              _buildField(
                                label: "Message *",
                                controller: _messageController,
                                placeholder: "Tell us more about your inquiry…",
                                minLines: 5,
                                maxLines: 6,
                              ),

                              AnimatedPressable(
                                pressScale: 0.97,
                                onPress: _sending ? null : _handleSubmit,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  decoration: BoxDecoration(
                                    color: AppColors.indigo.withValues(alpha: _sending ? 0.6 : 1.0),
                                    borderRadius: AppRadius.mdBorder,
                                  ),
                                  alignment: Alignment.center,
                                  child: _sending
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(LucideIcons.send, size: 16, color: Colors.white),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Send Message",
                                              style: AppTypography.label.copyWith(fontSize: 13.5, color: Colors.white),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Quick FAQs Accordion
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.helpCircle, size: 17, color: AppColors.indigo),
                                const SizedBox(width: 8),
                                Text(
                                  "Quick FAQs",
                                  style: AppTypography.h3.copyWith(fontSize: 15.5, color: AppColors.ink),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.lgBorder,
                                border: Border.all(color: AppColors.border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: _faqs.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final f = entry.value;
                                  final isOpen = _openFaq == idx;
                                  final isLast = idx == _faqs.length - 1;

                                  return Container(
                                    decoration: BoxDecoration(
                                      border: isLast
                                          ? null
                                          : Border(
                                              bottom: BorderSide(color: AppColors.border),
                                            ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AnimatedPressable(
                                          pressScale: 0.99,
                                          onPress: () => setState(() => _openFaq = isOpen ? null : idx),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.lg,
                                              vertical: 13,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    f['q']!,
                                                    style: AppTypography.bodyMedium.copyWith(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.ink,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                                  size: 16,
                                                  color: AppColors.inkMuted,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (isOpen)
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              AppSpacing.lg,
                                              0,
                                              AppSpacing.lg,
                                              AppSpacing.md,
                                            ),
                                            child: Text(
                                              f['a']!,
                                              style: AppTypography.body.copyWith(
                                                fontSize: 12.5,
                                                color: AppColors.inkMuted,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Social Links
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Follow Us",
                                style: AppTypography.h3.copyWith(fontSize: 15.5, color: AppColors.ink),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: _socialLinks.map((s) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: AnimatedPressable(
                                      pressScale: 0.9,
                                      onPress: () => _launchUrl(s['url'] as String),
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.indigoTint,
                                          borderRadius: AppRadius.mdBorder,
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(s['icon'] as IconData, size: 18, color: AppColors.indigo),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating 24/7 AI Bot Button
          Positioned(
            bottom: 24,
            right: 20,
            child: AnimatedPressable(
              pressScale: 0.9,
              onPress: () => setState(() => _chatOpen = true),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.indigo,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(27, 44, 92, 0.35),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(LucideIcons.bot, size: 24, color: Colors.white),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // AI Chat Widget
          ChatWidget(
            visible: _chatOpen,
            onClose: () => setState(() => _chatOpen = false),
          ),
        ],
      ),
    ),
  );
}
}
