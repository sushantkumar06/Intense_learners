import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../components/safe_back_scope.dart';
import '../../components/ui/ui.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _tab = "notifications";
  bool _downloading = false;

  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _assignmentReminders = true;
  bool _allowMessaging = true;
  bool _profileVisible = true;

  Future<void> _handleDownloadData() async {
    final user = ref.read(authProvider).user;
    final userId = user?['id'] ?? user?['_id'];
    if (user == null || userId == null) return;

    setState(() => _downloading = true);
    try {
      final response = await ref.read(dioProvider).get('/api/user/profile/$userId');
      final rawData = response.data;
      final userData = (rawData is Map && rawData['user'] is Map)
          ? rawData['user'] as Map
          : (rawData is Map ? rawData : user);

      final exportData = {
        "personalInformation": {
          "name": userData['name'],
          "email": userData['email'],
          "phone": userData['phone'],
          "location": userData['location'],
          "dateOfBirth": userData['dateOfBirth'],
          "bio": userData['bio'],
        },
        "professionalInformation": {
          "role": userData['role'],
          "qualification": userData['qualification'],
          "experience": userData['experience'],
          "subjects": userData['subjects'],
          "specialization": userData['specialization'],
          "teachingStyle": userData['teachingStyle'],
        },
        "socialProfiles": {
          "website": userData['website'],
          "linkedin": userData['linkedin'],
          "twitter": userData['twitter'],
          "instagram": userData['instagram'],
        },
      };

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
            title: Text(
              "Exported Data",
              style: AppTypography.h3.copyWith(fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Text(
                const JsonEncoder.withIndent('  ').convert(exportData),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
                child: Text(
                  "Close",
                  style: AppTypography.label.copyWith(color: AppColors.indigo),
                ),
              ),
            ],
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch your data. Please try again.")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  void _handleDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          "Delete Account",
          style: AppTypography.h3.copyWith(fontSize: 18),
        ),
        content: Text(
          "This will permanently delete your account and all associated data. This cannot be undone. Please contact support to proceed.",
          style: AppTypography.body.copyWith(fontSize: 14, color: AppColors.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            child: Text(
              "OK",
              style: AppTypography.label.copyWith(color: AppColors.indigo),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          "Log out?",
          style: AppTypography.h3.copyWith(fontSize: 18),
        ),
        content: Text(
          "Are you sure you want to log out?",
          style: AppTypography.body.copyWith(fontSize: 14, color: AppColors.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            child: Text(
              "Cancel",
              style: AppTypography.label.copyWith(color: AppColors.inkMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx, rootNavigator: true).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: Text(
              "Log Out",
              style: AppTypography.label.copyWith(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool last = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: AppColors.border),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  desc,
                  style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.indigo,
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool last = false,
  }) {
    return AnimatedPressable(
      pressScale: 0.98,
      onPress: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 13),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: AppRadius.smBorder,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: AppColors.indigo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {"id": "notifications", "label": "Notifications", "icon": LucideIcons.bell},
      {"id": "privacy", "label": "Privacy", "icon": LucideIcons.shield},
      {"id": "advanced", "label": "Advanced", "icon": LucideIcons.database},
    ];

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
                  Text(
                    "Settings",
                    style: AppTypography.h3.copyWith(fontSize: 16, color: AppColors.ink),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: tabs.map((t) {
                  final isSelected = _tab == t["id"];
                  return Expanded(
                    child: AnimatedPressable(
                      pressScale: 0.96,
                      onPress: () => setState(() => _tab = t["id"] as String),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected ? AppColors.indigo : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              t["icon"] as IconData,
                              size: 13,
                              color: isSelected ? AppColors.indigo : AppColors.inkFaint,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              t["label"] as String,
                              style: AppTypography.label.copyWith(
                                fontSize: 12,
                                color: isSelected ? AppColors.indigo : AppColors.inkFaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Scrollable Settings Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    if (_tab == "notifications") ...[
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.lgBorder,
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _buildToggleRow(
                              label: "Push Notifications",
                              desc: "Get notified on your device",
                              value: _pushNotifications,
                              onChanged: (v) => setState(() => _pushNotifications = v),
                            ),
                            _buildToggleRow(
                              label: "Email Notifications",
                              desc: "Receive updates via email",
                              value: _emailNotifications,
                              onChanged: (v) => setState(() => _emailNotifications = v),
                            ),
                            _buildToggleRow(
                              label: "Assignment Reminders",
                              desc: "Reminders before due dates",
                              value: _assignmentReminders,
                              onChanged: (v) => setState(() => _assignmentReminders = v),
                              last: true,
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_tab == "privacy") ...[
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.lgBorder,
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _buildToggleRow(
                              label: "Direct Messaging",
                              desc: "Allow others to message you",
                              value: _allowMessaging,
                              onChanged: (v) => setState(() => _allowMessaging = v),
                            ),
                            _buildToggleRow(
                              label: "Profile Visibility",
                              desc: "Show your profile to others",
                              value: _profileVisible,
                              onChanged: (v) => setState(() => _profileVisible = v),
                              last: true,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        margin: const EdgeInsets.only(top: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.indigoTint,
                          borderRadius: AppRadius.mdBorder,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(LucideIcons.info, size: 16, color: AppColors.indigo),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Your data is encrypted and secure. We never share it without your consent.",
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.indigo,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        "LEGAL & POLICIES",
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.lgBorder,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildLegalRow(
                              title: "Privacy Policy",
                              subtitle: "How we collect, protect, and use your data",
                              icon: LucideIcons.shield,
                              onTap: () => context.push('/shared/legal?type=privacy'),
                            ),
                            _buildLegalRow(
                              title: "Terms of Service",
                              subtitle: "Platform rules, student rights, and obligations",
                              icon: LucideIcons.fileText,
                              onTap: () => context.push('/shared/legal?type=terms'),
                            ),
                            _buildLegalRow(
                              title: "Refund Policy",
                              subtitle: "Order cancellations, UPI refunds, and timelines",
                              icon: LucideIcons.rotateCcw,
                              onTap: () => context.push('/shared/legal?type=refund'),
                            ),
                            _buildLegalRow(
                              title: "Cookie & Storage Policy",
                              subtitle: "How session data and local cache are handled",
                              icon: LucideIcons.cookie,
                              onTap: () => context.push('/shared/legal?type=cookie'),
                              last: true,
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_tab == "advanced") ...[
                      AnimatedPressable(
                        pressScale: 0.98,
                        onPress: _downloading ? null : _handleDownloadData,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.lgBorder,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              if (_downloading)
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.indigo,
                                  ),
                                )
                              else
                                Icon(LucideIcons.download, size: 18, color: AppColors.indigo),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Download Your Data",
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    Text(
                                      "Export your profile information",
                                      style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      AnimatedPressable(
                        pressScale: 0.98,
                        onPress: _handleDeleteAccount,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.coralTint,
                            borderRadius: AppRadius.lgBorder,
                            border: Border.all(
                              color: AppColors.coral.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.trash2, size: 18, color: AppColors.coral),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Delete Account",
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.coral,
                                      ),
                                    ),
                                    Text(
                                      "Permanently delete your account and data",
                                      style: AppTypography.caption.copyWith(color: AppColors.coral),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: AppRadius.lgBorder,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(LucideIcons.helpCircle, size: 18, color: AppColors.inkMuted),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Need Help?",
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "Contact support for assistance.",
                                    style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  AnimatedPressable(
                                    pressScale: 0.95,
                                    onPress: () => context.push('/student/contact'),
                                    child: Text(
                                      "Contact Support →",
                                      style: AppTypography.label.copyWith(
                                        fontSize: 12,
                                        color: AppColors.indigo,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                    AnimatedPressable(
                      pressScale: 0.97,
                      onPress: _handleLogout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.coralTint,
                          borderRadius: AppRadius.mdBorder,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.logOut, size: 16, color: AppColors.coral),
                            const SizedBox(width: 8),
                            Text(
                              "Log Out",
                              style: AppTypography.label.copyWith(
                                fontSize: 13.5,
                                color: AppColors.coral,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
}
