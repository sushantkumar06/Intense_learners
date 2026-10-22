import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:coaching_app_flutter/theme/app_theme.dart';

class PaymentMethodModal extends StatelessWidget {
  final bool visible;
  final num total;
  final bool showCod;
  final VoidCallback onClose;
  final Function(String method) onSelect;

  const PaymentMethodModal({
    super.key,
    required this.visible,
    required this.total,
    required this.showCod,
    required this.onClose,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: Stack(
        children: [
          AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: GestureDetector(
              onTap: onClose,
              child: Container(color: Colors.black.withValues(alpha: 0.7)),
            ),
          ),
          AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: kGlassModalFillGradient,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0x33FFFFFF), width: 1),
                  boxShadow: kGlassCardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Select Payment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 2),
                              Text("Total: ₹$total", style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                            ],
                          ),
                          GestureDetector(
                            onTap: onClose,
                            child: const Icon(LucideIcons.x, size: 22, color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0x1FFFFFFF)),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => onSelect("qr"),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0x14FFFFFF),
                                border: Border.all(color: const Color(0x2EFFFFFF), width: 1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 56, height: 56,
                                    decoration: BoxDecoration(color: const Color(0x2E2EE6C5), borderRadius: BorderRadius.circular(16)),
                                    alignment: Alignment.center,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: const Icon(LucideIcons.qrCode, size: 26, color: Color(0xFF2EE6C5)),
                                  ),
                                  const Text("Pay via QR", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  const Text("Scan & pay with any UPI app", style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                                ],
                              ),
                            ),
                          ),
                          if (showCod) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => onSelect("cod"),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0x14FFFFFF),
                                  border: Border.all(color: const Color(0x2EFFFFFF), width: 1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 56, height: 56,
                                      decoration: BoxDecoration(color: const Color(0x2E2EE6A8), borderRadius: BorderRadius.circular(16)),
                                      alignment: Alignment.center,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: const Icon(LucideIcons.dollarSign, size: 26, color: Color(0xFF2EE6A8)),
                                    ),
                                    const Text("Cash on Delivery", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(height: 4),
                                    const Text("Pay when you receive", style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
