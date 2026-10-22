import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppInput extends StatefulWidget {
  final String? label;
  final String? error;
  final String? placeholder;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final bool enabled;
  final int maxLines;
  final FocusNode? focusNode;

  const AppInput({
    super.key,
    this.label,
    this.error,
    this.placeholder,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.leftIcon,
    this.rightIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null && widget.error!.isNotEmpty;

    Color borderColor;
    List<BoxShadow>? glowShadow;

    if (hasError) {
      borderColor = const Color(0xFFFF6B6B);
      glowShadow = const [
        BoxShadow(
          color: Color(0x40FF6B6B),
          blurRadius: 14,
          spreadRadius: 0,
          offset: Offset(0, 2),
        ),
      ];
    } else if (_isFocused) {
      borderColor = const Color(0x992EE6C5); // accent at 60%
      glowShadow = const [
        BoxShadow(
          color: Color(0x4D2EE6C5), // accent glow
          blurRadius: 16,
          spreadRadius: 0,
          offset: Offset(0, 2),
        ),
      ];
    } else {
      borderColor = const Color(0x33FFFFFF); // white ~20%
      glowShadow = const [
        BoxShadow(
          color: Color(0x1F000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x1FFFFFFF), // translucent glass top-left
                Color(0x0DFFFFFF), // subtle fade bottom-right
              ],
            ),
            border: Border.all(
              color: borderColor,
              width: 1.0,
            ),
            boxShadow: glowShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              color: const Color(0x1F203A43), // deep teal tint
              child: Row(
                children: [
                  if (widget.leftIcon != null) ...[
                    widget.leftIcon!,
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: TextField(
                      focusNode: _focusNode,
                      controller: widget.controller,
                      obscureText: widget.obscureText,
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      enabled: widget.enabled,
                      maxLines: widget.maxLines,
                      cursorColor: const Color(0xFF2EE6C5),
                      style: AppTypography.body.copyWith(
                        color: AppColors.ink,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.placeholder,
                        hintStyle: AppTypography.body.copyWith(
                          color: AppColors.inkFaint,
                        ),
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                  if (widget.rightIcon != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    widget.rightIcon!,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.error!,
            style: AppTypography.body.copyWith(
              fontSize: 12,
              color: const Color(0xFFFF6B6B),
            ),
          ),
        ],
      ],
    );
  }
}
