import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/assignment.dart';
import '../../theme/app_theme.dart';
import '../ui/ui.dart';

class AssignmentCard extends StatefulWidget {
  final StudentAssignment assignment;
  final VoidCallback onSubmit;
  final VoidCallback onViewComments;
  final ValueChanged<String> onMarkCompleted;

  const AssignmentCard({
    super.key,
    required this.assignment,
    required this.onSubmit,
    required this.onViewComments,
    required this.onMarkCompleted,
  });

  @override
  State<AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<AssignmentCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
    final dueDate = assignment.dueDate;
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    final daysLeft = difference.inDays;
    final hoursLeft = difference.inHours;

    String timeLeftText;
    Color timeLeftColor;
    if (daysLeft > 1) {
      timeLeftText = "$daysLeft days left";
      timeLeftColor = AppColors.mint;
    } else if (hoursLeft > 1) {
      timeLeftText = "$hoursLeft hours left";
      timeLeftColor = AppColors.coral;
    } else if (daysLeft < 0) {
      timeLeftText = "Past due";
      timeLeftColor = AppColors.inkFaint;
    } else {
      timeLeftText = "Due soon";
      timeLeftColor = AppColors.coral;
    }

    String statusLabel;
    AppBadgeTone statusTone;
    if (assignment.mySubmission?.isCompleted == true) {
      statusLabel = "Completed";
      statusTone = AppBadgeTone.success;
    } else if (assignment.mySubmission != null) {
      statusLabel = "Submitted";
      statusTone = AppBadgeTone.brand;
    } else {
      statusLabel = "Pending";
      statusTone = AppBadgeTone.gold;
    }

    final canExpand = assignment.description.length > 100;
    final teacherName = (assignment.teacher['name'] as String?) ?? 'Teacher';
    final totalSubmissions =
        (assignment.stats['totalSubmissions'] as num?)?.toInt() ?? 0;
    final totalComments =
        (assignment.stats['totalComments'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      child: AppCard(
        elevation: AppCardElevation.flat,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    assignment.title,
                    style: AppTypography.h3.copyWith(
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppBadge(
                  label: statusLabel,
                  tone: statusTone,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Subject & Class Badges
            Row(
              children: [
                AppBadge(
                  label: assignment.subject,
                  tone: AppBadgeTone.brand,
                ),
                const SizedBox(width: 6),
                AppBadge(
                  label: assignment.className,
                  tone: AppBadgeTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Description
            Text(
              assignment.description,
              style: AppTypography.body.copyWith(
                fontSize: 13.5,
                color: AppColors.inkMuted,
                height: 19 / 13.5,
              ),
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
            if (canExpand) ...[
              const SizedBox(height: 4),
              AnimatedPressable(
                pressScale: 0.95,
                onPress: () => setState(() => _expanded = !_expanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expanded ? "Show less" : "Read more",
                      style: AppTypography.label.copyWith(
                        color: AppColors.indigo,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 14,
                      color: AppColors.indigo,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),

            // Meta row
            Wrap(
              spacing: 16,
              runSpacing: 7,
              children: [
                _buildMetaItem(
                  icon: LucideIcons.user,
                  text: teacherName,
                ),
                _buildMetaItem(
                  icon: LucideIcons.calendar,
                  text: "Due ${dueDate.day}/${dueDate.month}/${dueDate.year}",
                ),
                _buildMetaItem(
                  icon: LucideIcons.clock,
                  text: timeLeftText,
                  color: timeLeftColor,
                ),
                _buildMetaItem(
                  icon: LucideIcons.award,
                  text: "${assignment.totalMarks} marks",
                ),
                _buildMetaItem(
                  icon: LucideIcons.users,
                  text: "$totalSubmissions submissions",
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Submission Box (if submitted)
            if (assignment.mySubmission != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.indigoTint,
                  borderRadius: AppRadius.mdBorder,
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.indigo,
                            borderRadius: AppRadius.smBorder,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            LucideIcons.checkCircle2,
                            size: 17,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Your Submission",
                                style: AppTypography.label.copyWith(
                                  color: AppColors.indigoDark,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.fileText,
                                    size: 11,
                                    color: AppColors.indigo,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "${assignment.mySubmission!.fileName} · ${assignment.mySubmission!.fileSize}",
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.indigo,
                                        fontSize: 11.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (assignment.mySubmission!.remarks != null &&
                                  assignment.mySubmission!.remarks!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '"${assignment.mySubmission!.remarks}"',
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.indigoDark,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: "View",
                            icon: LucideIcons.eye,
                            size: AppButtonSize.sm,
                            onPress: () => launchUrl(
                              Uri.parse(assignment.mySubmission!.fileUrl),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                        ),
                        if (!assignment.mySubmission!.isCompleted) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppButton(
                              label: "Mark Done",
                              icon: LucideIcons.check,
                              size: AppButtonSize.sm,
                              variant: AppButtonVariant.primary,
                              onPress: () => widget.onMarkCompleted(
                                assignment.mySubmission!.id,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (assignment.fileUrl != null &&
                    assignment.fileUrl!.isNotEmpty)
                  AppButton(
                    label: "Download",
                    icon: LucideIcons.download,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.sm,
                    onPress: () => launchUrl(
                      Uri.parse(assignment.fileUrl!),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                if (assignment.mySubmission == null)
                  AppButton(
                    label: "Submit",
                    icon: LucideIcons.upload,
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.sm,
                    onPress: widget.onSubmit,
                  ),
                AppButton(
                  label: "Discuss ($totalComments)",
                  icon: LucideIcons.messageSquare,
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.sm,
                  onPress: widget.onViewComments,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.inkMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color ?? AppColors.inkFaint),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.caption.copyWith(
            color: effectiveColor,
            fontSize: 11.5,
            fontWeight: color != null ? FontWeight.w600 : FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
