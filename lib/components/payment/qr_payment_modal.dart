import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:coaching_app_flutter/theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../services/upload_service.dart';
import '../../models/payment.dart';

class QRPaymentModal extends ConsumerStatefulWidget {
  final bool visible;
  final PaymentOrderFull? order;
  final VoidCallback onClose;
  final VoidCallback onSuccess;

  const QRPaymentModal({
    super.key,
    required this.visible,
    required this.order,
    required this.onClose,
    required this.onSuccess,
  });

  @override
  ConsumerState<QRPaymentModal> createState() => _QRPaymentModalState();
}

class _QRPaymentModalState extends ConsumerState<QRPaymentModal> {
  String? _proofUrl;
  bool _uploading = false;
  bool _submitting = false;

  Future<void> _handlePickProof() async {
    setState(() => _uploading = true);
    try {
      final uploadService = ref.read(uploadServiceProvider);
      final file = await uploadService.pickAndUploadImage();
      if (file != null) {
        setState(() => _proofUrl = file.url);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _handleSubmitProof() async {
    if (_proofUrl == null || widget.order == null) return;
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/api/payments', data: {
        "action": "update-payment-proof",
        "orderId": widget.order!.id,
        "proofUrl": _proofUrl,
      });

      if (response.data['success'] == true) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Submitted! We'll verify your order shortly.")));
        setState(() => _proofUrl = null);
        widget.onSuccess();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data['error'] ?? "Failed to update order")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to upload proof")));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.order == null) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: !widget.visible,
      child: Stack(
        children: [
          AnimatedOpacity(
            opacity: widget.visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(color: Colors.black.withValues(alpha: 0.7)),
            ),
          ),
          AnimatedSlide(
            offset: widget.visible ? Offset.zero : const Offset(0, 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                bottom: true,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: kGlassModalFillGradient,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
                    boxShadow: kGlassCardShadow,
                  ),
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Complete Payment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 2),
                                Text("Order #${widget.order!.id.substring(0, 8)} · ₹${widget.order!.total}", style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                              ],
                            ),
                            GestureDetector(
                              onTap: widget.onClose,
                              child: const Icon(LucideIcons.x, size: 22, color: AppColors.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0x1FFFFFFF)),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: const Color(0x14FFFFFF),
                                  border: Border.all(color: const Color(0x2EFFFFFF), width: 1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    const Text("Scan & Pay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(height: 12),
                                    Container(
                                      width: 176, height: 176,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                      child: Image.network("https://intense-learners.vercel.app/paytm-qr-placeholder.jpeg", fit: BoxFit.contain),
                                    ),
                                    const SizedBox(height: 12),
                                    RichText(
                                      text: TextSpan(
                                        text: "Pay ",
                                        style: const TextStyle(fontSize: 14, color: Colors.white),
                                        children: [
                                          TextSpan(text: "₹${widget.order!.total}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2EE6C5))),
                                          const TextSpan(text: " via any UPI app"),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: const TextSpan(
                                        text: "UPI ID: ",
                                        style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                                        children: [
                                          TextSpan(text: "9810493309@ptsbi", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2EE6C5))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Text("Upload Payment Screenshot", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 8),
                              if (_proofUrl != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0x14FFFFFF),
                                    border: Border.all(color: const Color(0x662EE6C5), width: 1.5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(_proofUrl!, height: 140, width: double.infinity, fit: BoxFit.cover),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () => setState(() => _proofUrl = null),
                                        child: const Text("Remove", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B))),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: _uploading ? null : _handlePickProof,
                                  child: Container(
                                    height: 140,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0x0FFFFFFF),
                                      border: Border.all(color: const Color(0x26FFFFFF), width: 1.5, style: BorderStyle.solid),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    alignment: Alignment.center,
                                    child: _uploading
                                        ? const CircularProgressIndicator(color: Color(0xFF2EE6C5))
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(LucideIcons.upload, size: 24, color: AppColors.inkMuted),
                                              const SizedBox(height: 8),
                                              Text("Tap to upload screenshot", style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                                            ],
                                          ),
                                  ),
                                ),
                              ElevatedButton(
                                onPressed: (_submitting || _proofUrl == null) ? null : _handleSubmitProof,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2EE6C5),
                                  foregroundColor: const Color(0xFF0F2027),
                                  disabledBackgroundColor: const Color(0xFF2EE6C5).withValues(alpha: 0.3),
                                  disabledForegroundColor: const Color(0xFF0F2027).withValues(alpha: 0.5),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: const StadiumBorder(),
                                  elevation: 0,
                                  shadowColor: const Color(0x522EE6C5),
                                ),
                                child: _submitting 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF0F2027), strokeWidth: 2))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(LucideIcons.send, size: 16),
                                        SizedBox(width: 8),
                                        Text("Submit for Verification", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
