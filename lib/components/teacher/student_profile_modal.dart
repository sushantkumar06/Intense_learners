import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:coaching_app_flutter/theme/app_theme.dart';
import '../../models/teacher_assignment.dart';

class StudentProfileModal extends StatelessWidget {
  final TeacherStudentProfile student;

  const StudentProfileModal({super.key, required this.student});

  int? _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return null;
    try {
      final birth = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birth.year;
      if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: BoxDecoration(
          gradient: kGlassModalFillGradient,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0x33FFFFFF), width: 1),
          boxShadow: kGlassCardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0x1FFFFFFF))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Student Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: const Icon(LucideIcons.x, size: 22, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar & Name
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          Container(
                            width: 80, height: 80,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0x2E2EE6C5),
                              border: Border.all(color: const Color(0x662EE6C5), width: 1.5),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            alignment: Alignment.center,
                            clipBehavior: Clip.antiAlias,
                            child: (student.avatar != null && student.avatar!.isNotEmpty)
                                ? Image.network(student.avatar!, width: 80, height: 80, fit: BoxFit.cover)
                                : Text(student.name?.isNotEmpty == true ? student.name![0].toUpperCase() : "?", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2EE6C5))),
                          ),
                          Text(student.name ?? "Unknown", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(student.email ?? "", style: const TextStyle(fontSize: 14, color: AppColors.inkMuted)),
                        ],
                      ),
                    ),

                    // Details
                    if (student.phone != null && student.phone!.isNotEmpty)
                      _buildInfoRow(LucideIcons.phone, "Phone", student.phone!),
                    if (student.location != null && student.location!.isNotEmpty)
                      _buildInfoRow(LucideIcons.mapPin, "Location", student.location!),
                    if (student.dateOfBirth != null && student.dateOfBirth!.isNotEmpty)
                      Builder(builder: (ctx) {
                        final age = _calculateAge(student.dateOfBirth);
                        if (age == null) return const SizedBox();
                        return _buildInfoRow(LucideIcons.cake, "Age", "$age years old");
                      }),
                    if (student.bio != null && student.bio!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x14FFFFFF),
                          border: Border.all(color: const Color(0x26FFFFFF), width: 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Bio", style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                            const SizedBox(height: 4),
                            Text(student.bio!, style: const TextStyle(fontSize: 14, color: Colors.white)),
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
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        border: Border.all(color: const Color(0x26FFFFFF), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2EE6C5)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          )
        ],
      ),
    );
  }
}
