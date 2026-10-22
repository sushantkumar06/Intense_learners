import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:coaching_app_flutter/theme/app_theme.dart';

class HolidayFormModal extends StatefulWidget {
  final String dateKey;
  final Future<bool> Function(String title, String date) onSave;

  const HolidayFormModal({
    super.key,
    required this.dateKey,
    required this.onSave,
  });

  @override
  State<HolidayFormModal> createState() => _HolidayFormModalState();
}

class _HolidayFormModalState extends State<HolidayFormModal> {
  final TextEditingController _titleController = TextEditingController();
  bool _submitting = false;

  static const _dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
  static const _monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

  String _formatDateLabel(String dateKey) {
    try {
      final d = DateTime.parse("${dateKey}T00:00:00");
      return "${_dayNames[d.weekday % 7]}, ${_monthNames[d.month - 1]} ${d.day}";
    } catch (_) {
      return dateKey;
    }
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    if (_titleController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a title for this holiday"), backgroundColor: Color(0xFFFF6B6B)));
      }
      return;
    }
    setState(() => _submitting = true);
    final ok = await widget.onSave(_titleController.text.trim(), widget.dateKey);
    if (mounted) {
      if (ok) {
        Navigator.of(context).pop();
      } else {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x1FFFFFFF)))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Add Custom Holiday", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(_formatDateLabel(widget.dateKey), style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                    ],
                  ),
                  GestureDetector(
                    onTap: _submitting ? null : () => Navigator.of(context).pop(),
                    child: const Icon(LucideIcons.x, size: 22, color: AppColors.inkMuted),
                  )
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Title *", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    cursorColor: const Color(0xFF2EE6C5),
                    decoration: InputDecoration(
                      hintText: "e.g., Institute Anniversary",
                      hintStyle: const TextStyle(color: AppColors.inkFaint),
                      filled: true,
                      fillColor: const Color(0x14FFFFFF),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0x26FFFFFF), width: 1)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0x26FFFFFF), width: 1)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0x992EE6C5), width: 1.5)),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x1FFFFFFF)))),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _submitting ? null : () => Navigator.of(context).pop(),
                      child: Opacity(
                        opacity: _submitting ? 0.5 : 1.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0x14FFFFFF),
                            border: Border.all(color: const Color(0x33FFFFFF), width: 1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: const Text("Cancel", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _submitting ? null : _handleSubmit,
                      child: Opacity(
                        opacity: _submitting ? 0.45 : 1.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2EE6C5),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: _submitting ? null : const [
                              BoxShadow(
                                color: Color(0x522EE6C5),
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _submitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF0F2027), strokeWidth: 2))
                              : const Text("Add Holiday", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F2027))),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
