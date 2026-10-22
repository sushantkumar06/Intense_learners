import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/safe_back_scope.dart';
import '../../components/ui/ui.dart';
import '../../theme/app_theme.dart';

enum LegalPolicyType {
  terms,
  privacy,
  refund,
  cookie,
}

class LegalScreen extends StatefulWidget {
  final LegalPolicyType initialPolicy;

  const LegalScreen({
    super.key,
    this.initialPolicy = LegalPolicyType.terms,
  });

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  late LegalPolicyType _selectedPolicy;

  @override
  void initState() {
    super.initState();
    _selectedPolicy = widget.initialPolicy;
  }

  @override
  Widget build(BuildContext context) {
    return SafeBackScope(
      fallbackLocation: '/student/dashboard',
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Column(
            children: [
              // Top App Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
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
                          context.go('/student/dashboard');
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getPolicyTitle(_selectedPolicy),
                          style: AppTypography.h3.copyWith(fontSize: 16, color: AppColors.ink),
                        ),
                        Text(
                          "Last updated June 2026 · Intense Learners",
                          style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _getPolicyToneColor(_selectedPolicy).withValues(alpha: 0.12),
                      borderRadius: AppRadius.smBorder,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _getPolicyIcon(_selectedPolicy),
                      size: 18,
                      color: _getPolicyToneColor(_selectedPolicy),
                    ),
                  ),
                ],
              ),
            ),

            // Policy Navigation Tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPolicyTab(
                      type: LegalPolicyType.terms,
                      label: "Terms of Service",
                      icon: LucideIcons.fileText,
                    ),
                    const SizedBox(width: 8),
                    _buildPolicyTab(
                      type: LegalPolicyType.privacy,
                      label: "Privacy Policy",
                      icon: LucideIcons.shield,
                    ),
                    const SizedBox(width: 8),
                    _buildPolicyTab(
                      type: LegalPolicyType.refund,
                      label: "Refund Policy",
                      icon: LucideIcons.rotateCcw,
                    ),
                    const SizedBox(width: 8),
                    _buildPolicyTab(
                      type: LegalPolicyType.cookie,
                      label: "Cookie Policy",
                      icon: LucideIcons.cookie,
                    ),
                  ],
                ),
              ),
            ),

            // Content Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPolicyHeaderBanner(),
                    const SizedBox(height: 20),
                    ..._buildPolicySections(_selectedPolicy),
                    const SizedBox(height: 32),
                    _buildContactCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildPolicyTab({
    required LegalPolicyType type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedPolicy == type;
    final color = _getPolicyToneColor(type);

    return AnimatedPressable(
      pressScale: 0.94,
      onPress: () => setState(() => _selectedPolicy = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surfaceMuted,
          borderRadius: AppRadius.pillBorder,
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? color : AppColors.inkMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isSelected ? color : AppColors.ink,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyHeaderBanner() {
    final title = _getPolicyTitle(_selectedPolicy);
    final summary = _getPolicySummary(_selectedPolicy);
    final color = _getPolicyToneColor(_selectedPolicy);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgBorder,
        border: Border(
          top: BorderSide(color: color, width: 3),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.pillBorder,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.sparkles, size: 11, color: color),
                    const SizedBox(width: 4),
                    Text(
                      "OFFICIAL DOCUMENT",
                      style: AppTypography.caption.copyWith(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                "Version 2.4",
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkFaint,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTypography.h2.copyWith(color: AppColors.ink, fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: AppTypography.body.copyWith(
              color: AppColors.inkMuted,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPolicySections(LegalPolicyType type) {
    switch (type) {
      case LegalPolicyType.terms:
        return [
          _buildSectionCard(
            number: "1",
            title: "Acceptance of Terms",
            body:
                "Welcome to Intense Learners! These Terms of Service govern your access to and use of our online coaching, recorded lectures, quizzes, and study planning platform. By signing in, creating an account, or browsing, you agree to comply with all terms stated herein.",
          ),
          _buildSectionCard(
            number: "2",
            title: "Eligibility & User Accounts",
            body:
                "Students and teachers must provide accurate, up-to-date information during registration. You are responsible for safeguarding your credentials and for all activities under your account. Notify support immediately if unauthorized access occurs.",
          ),
          _buildSectionCard(
            number: "3",
            title: "Student & Teacher Roles",
            body:
                "• Students may access enrolled notes, assignments, mock tests, and community doubt solving.\n• Teachers can publish course materials, manage video folders, answer doubts, and review student assignments.\n• Registration as a teacher requires a valid verification code provided by institute administrators.",
          ),
          _buildSectionCard(
            number: "4",
            title: "Intellectual Property",
            body:
                "All lecture videos, notes, mock exams, and platform brand assets are the exclusive property of Intense Learners and licensed educators. Unauthorized redistribution, copying, or downloading outside authorized offline caches is strictly prohibited.",
          ),
          _buildSectionCard(
            number: "5",
            title: "AI-Assisted Learning",
            body:
                "Our AI Study Planner and Teacher AI Assistant provide algorithmic recommendations based on your curriculum goals. While optimized for accuracy, users should verify complex formulas and curriculum guidelines with their respective syllabus.",
          ),
          _buildSectionCard(
            number: "6",
            title: "Community Guidelines & Acceptable Use",
            body:
                "Harassment, abusive doubt messages, spam, or uploading infringing material will result in immediate account suspension. Our team actively moderates doubt discussions and comment threads to maintain an uplifting learning space.",
          ),
        ];

      case LegalPolicyType.privacy:
        return [
          _buildSectionCard(
            number: "1",
            title: "Information We Collect",
            body:
                "• Account Details: Name, email address, password hash, and student profile preferences.\n• Academic Activity: Quiz scores, assignment submissions, video watch time, and doubts asked.\n• Technical Diagnostics: Device type, app version, and crash logs to improve platform performance.",
          ),
          _buildSectionCard(
            number: "2",
            title: "How We Use Your Data",
            body:
                "Your information is used strictly to power educational features: personalizing study schedules, syncing watch progress, delivering doubt replies, and facilitating teacher grading. We never sell your personal data to third parties.",
          ),
          _buildSectionCard(
            number: "3",
            title: "Video Progress & Local Storage",
            body:
                "We record watch progress via encrypted endpoints so you can resume lectures seamlessly on any mobile or desktop device. Local caching via SharedPreferences stores your study planner schedules for offline readiness.",
          ),
          _buildSectionCard(
            number: "4",
            title: "Data Security & Encryption",
            body:
                "All API traffic is transmitted via HTTPS/TLS encryption. Sensitive authentication tokens are stored securely on your device using encrypted storage mechanisms.",
          ),
          _buildSectionCard(
            number: "5",
            title: "Your Rights & Account Deletion",
            body:
                "You can update your personal information or request full data export anytime in Settings. If you wish to delete your account and associated history, use the 'Delete Account' option in Settings or email support.",
          ),
        ];

      case LegalPolicyType.refund:
        return [
          _buildSectionCard(
            number: "1",
            title: "Overview & Philosophy",
            body:
                "We believe in transparent, fair, and prompt fee resolution. If an enrollment, test series purchase, or payment verification error occurs, we make every reasonable effort to resolve it within 7–10 business days.",
          ),
          _buildSectionCard(
            number: "2",
            title: "UPI & QR Payment Processing",
            body:
                "When submitting fee payments via QR / UPI, please ensure your transaction reference / UTR is entered correctly. In cases where the bank confirms deduction but our system cannot verify within 48 hours, a refund is triggered automatically.",
          ),
          _buildSectionCard(
            number: "3",
            title: "Course Cancellation Eligibility",
            body:
                "• Full Refund: Within 3 calendar days of course enrollment if you have watched less than 10% of total video lessons.\n• Partial Credit: In exceptional medical or relocation situations reviewed on a case-by-case basis by management.\n• Mock test series fees are non-refundable once tests have been attempted.",
          ),
          _buildSectionCard(
            number: "4",
            title: "Refund Timeline",
            body:
                "Approved refunds are credited back to the original source bank account or UPI VPA within 7–10 working days. Bank holidays may introduce slight delays outside our control.",
          ),
        ];

      case LegalPolicyType.cookie:
        return [
          _buildSectionCard(
            number: "1",
            title: "Mobile Storage & Identifiers",
            body:
                "While mobile apps do not use traditional browser cookies, we use local key-value storage and secure device tokens to preserve your login session, study planner checklists, and theme preferences.",
          ),
          _buildSectionCard(
            number: "2",
            title: "Essential Session Tokens",
            body:
                "Necessary for authentication and maintaining your secure session between app launches without prompting for repeated password entry.",
          ),
          _buildSectionCard(
            number: "3",
            title: "Analytics & Telemetry",
            body:
                "Aggregated session analytics help us identify crashing video streams and slow response times across different device models.",
          ),
          _buildSectionCard(
            number: "4",
            title: "Managing Local Data",
            body:
                "You can clear local cached data by logging out or tapping 'Reset Cache' in the Advanced Settings tab at any time.",
          ),
        ];
    }
  }

  Widget _buildSectionCard({
    required String number,
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: AppRadius.smBorder,
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: AppTypography.label.copyWith(
                    color: AppColors.indigo,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.label.copyWith(
                    color: AppColors.ink,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: AppTypography.body.copyWith(
              color: AppColors.inkMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.indigoDark,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: AppRadius.smBorder,
                ),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.mail, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                "Need Clarification?",
                style: AppTypography.label.copyWith(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "For legal queries, privacy rights, or fee support, reach our grievance officer at support@intensestudy.com or via the Contact Support screen.",
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          AnimatedPressable(
            pressScale: 0.96,
            onPress: () => context.push('/student/contact'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.pillBorder,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Contact Support",
                    style: AppTypography.label.copyWith(
                      color: AppColors.indigoDark,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(LucideIcons.arrowRight, size: 13, color: AppColors.indigoDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPolicyTitle(LegalPolicyType type) {
    switch (type) {
      case LegalPolicyType.terms:
        return "Terms of Service";
      case LegalPolicyType.privacy:
        return "Privacy Policy";
      case LegalPolicyType.refund:
        return "Refund Policy";
      case LegalPolicyType.cookie:
        return "Cookie Policy";
    }
  }

  String _getPolicySummary(LegalPolicyType type) {
    switch (type) {
      case LegalPolicyType.terms:
        return "Understand your rights, user obligations, intellectual property guidelines, and platform standards.";
      case LegalPolicyType.privacy:
        return "How we collect, protect, and process student progress and account information across devices.";
      case LegalPolicyType.refund:
        return "Clear guidelines on fee handling, UPI payment verification, and course cancellation timelines.";
      case LegalPolicyType.cookie:
        return "How session cache and local preferences are safely maintained on your mobile device.";
    }
  }

  IconData _getPolicyIcon(LegalPolicyType type) {
    switch (type) {
      case LegalPolicyType.terms:
        return LucideIcons.fileText;
      case LegalPolicyType.privacy:
        return LucideIcons.shield;
      case LegalPolicyType.refund:
        return LucideIcons.rotateCcw;
      case LegalPolicyType.cookie:
        return LucideIcons.cookie;
    }
  }

  Color _getPolicyToneColor(LegalPolicyType type) {
    switch (type) {
      case LegalPolicyType.terms:
        return AppColors.indigo;
      case LegalPolicyType.privacy:
        return AppColors.mint;
      case LegalPolicyType.refund:
        return AppColors.gold;
      case LegalPolicyType.cookie:
        return AppColors.coral;
    }
  }
}
