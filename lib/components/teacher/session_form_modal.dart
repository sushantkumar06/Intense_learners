import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:coaching_app_flutter/theme/app_theme.dart';
import '../../models/schedule.dart';

class SessionFormModal extends StatefulWidget {
  final ScheduleSession? session;
  final String dateKey;
  final Future<bool> Function(Map<String, dynamic> payload) onSave;
  final VoidCallback? onDelete;

  const SessionFormModal({
    super.key,
    this.session,
    required this.dateKey,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<SessionFormModal> createState() => _SessionFormModalState();
}

class _SessionFormModalState extends State<SessionFormModal> {
  late TextEditingController _titleController;
  late TextEditingController _subjectController;
  late TextEditingController _classController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late TextEditingController _notesController;

  static const _colors = [
    Color(0xFF3B82F6), Color(0xFFA855F7), Color(0xFF22C55E),
    Color(0xFFF97316), Color(0xFFEC4899), Color(0xFF14B8A6), Color(0xFFEAB308),
  ];

  late Color _selectedColor;
  bool _submitting = false;

  static const _dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
  static const _monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _titleController = TextEditingController(text: s?.title ?? "");
    _subjectController = TextEditingController(text: s?.subject ?? "");
    _classController = TextEditingController(text: s?.classLevel ?? "");
    _startTimeController = TextEditingController(text: s?.startTime ?? "09:00");
    _endTimeController = TextEditingController(text: s?.endTime ?? "10:00");
    _notesController = TextEditingController(text: s?.notes ?? "");

    _selectedColor = _colors.first;
    if (s != null && s.color.isNotEmpty) {
      try {
        final hex = s.color.replaceAll('#', '');
        if (hex.length == 6) {
          _selectedColor = Color(int.parse('FF$hex', radix: 16));
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _classController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDateLabel(String dateKey) {
    try {
      final d = DateTime.parse("${dateKey}T00:00:00");
      return "${_dayNames[d.weekday % 7]}, ${_monthNames[d.month - 1]} ${d.day}";
    } catch (_) {
      return dateKey;
    }
  }

  bool _isValidTime(String t) {
    return RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').hasMatch(t);
  }

  void _showAlert(String title, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$title: $message"), backgroundColor: Colors.red));
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;

    final title = _titleController.text.trim();
    final subject = _subjectController.text.trim();
    final className = _classController.text.trim();
    final startTime = _startTimeController.text.trim();
    final endTime = _endTimeController.text.trim();
    final notes = _notesController.text.trim();

    if (title.isEmpty || subject.isEmpty || className.isEmpty) {
      _showAlert("Missing info", "Please fill in title, subject, and class");
      return;
    }
    if (!_isValidTime(startTime) || !_isValidTime(endTime)) {
      _showAlert("Invalid time", "Please enter times as HH:MM (24-hour), e.g. 09:00");
      return;
    }
    if (startTime.compareTo(endTime) >= 0) {
      _showAlert("Invalid time", "End time must be after start time");
      return;
    }

    setState(() => _submitting = true);

    final int r = (_selectedColor.r * 255.0).round().clamp(0, 255);
    final int g = (_selectedColor.g * 255.0).round().clamp(0, 255);
    final int b = (_selectedColor.b * 255.0).round().clamp(0, 255);
    final String hexColor = '#${((r << 16) | (g << 8) | b).toRadixString(16).padLeft(6, '0')}';

    final payload = {
      'id': widget.session?.id,
      'title': title,
      'subject': subject,
      'class': className,
      'date': widget.dateKey,
      'startTime': startTime,
      'endTime': endTime,
      'color': hexColor,
      'notes': notes.isEmpty ? null : notes,
    };

    final ok = await widget.onSave(payload);
    if (mounted) {
      if (ok) {
        Navigator.of(context).pop();
      } else {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {bool isTime = false, bool multiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: multiline ? 3 : 1,
          minLines: multiline ? 3 : 1,
          keyboardType: isTime ? TextInputType.datetime : (multiline ? TextInputType.multiline : TextInputType.text),
          style: const TextStyle(fontSize: 14, color: Colors.white),
          cursorColor: const Color(0xFF2EE6C5),
          decoration: InputDecoration(
            hintText: hint,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.session != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          gradient: kGlassModalFillGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
          boxShadow: kGlassCardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
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
                        Text(isEdit ? "Edit Session" : "New Session", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
              
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField("Title *", _titleController, "e.g., Physics Live Class"),
                      const SizedBox(height: 16),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTextField("Subject *", _subjectController, "Physics")),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField("Class *", _classController, "Class 12")),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTextField("Start Time *", _startTimeController, "09:00", isTime: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField("End Time *", _endTimeController, "10:00", isTime: true)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text("24-hour format, e.g. 14:30", style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                      const SizedBox(height: 16),

                      const Text("Color Tag", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _colors.map((c) => GestureDetector(
                          onTap: () => setState(() => _selectedColor = c),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedColor == c ? const Color(0xFF2EE6C5) : Colors.transparent,
                                width: _selectedColor == c ? 3 : 0,
                              )
                            ),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),

                      _buildTextField("Notes (Optional)", _notesController, "Optional notes about this session...", multiline: true),
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x1FFFFFFF)))),
                child: Row(
                  children: [
                    if (isEdit && widget.onDelete != null) ...[
                      GestureDetector(
                        onTap: _submitting ? null : widget.onDelete,
                        child: Opacity(
                          opacity: _submitting ? 0.5 : 1.0,
                          child: Container(
                            width: 48,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0x14FFFFFF),
                              border: Border.all(color: const Color(0x66FF6B6B), width: 1.5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFFF6B6B)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
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
                      flex: 2,
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
                                : Text(isEdit ? "Save Changes" : "Add Session", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F2027))),
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
      ),
    );
  }
}
