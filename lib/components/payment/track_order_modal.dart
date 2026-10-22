import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:coaching_app_flutter/theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../models/payment.dart';

class TrackOrderModal extends ConsumerStatefulWidget {
  final bool visible;
  final VoidCallback onClose;

  const TrackOrderModal({
    super.key,
    required this.visible,
    required this.onClose,
  });

  @override
  ConsumerState<TrackOrderModal> createState() => _TrackOrderModalState();
}

class _TrackOrderModalState extends ConsumerState<TrackOrderModal> {
  String _id = "";
  bool _busy = false;
  String _error = "";
  PaymentOrderFull? _order;

  Future<void> _search() async {
    if (_id.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = "";
    });

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/api/payments?action=order-status&orderId=${Uri.encodeComponent(_id.trim())}');
      
      if (response.data['success'] == true) {
        setState(() => _order = PaymentOrderFull.fromJson(response.data['order']));
      } else {
        setState(() => _error = response.data['error'] ?? "Order not found");
      }
    } catch (e) {
      setState(() => _error = "Order not found");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _handleClose() {
    setState(() {
      _id = "";
      _error = "";
      _order = null;
    });
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Stack(
      children: [
        GestureDetector(
          onTap: _handleClose,
          child: Container(color: Colors.black.withValues(alpha: 0.7)),
        ),
        Center(
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
                      Text(_order != null ? "Order Status" : "Track Order", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      GestureDetector(
                        onTap: _handleClose,
                        child: const Icon(LucideIcons.x, size: 22, color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0x1FFFFFFF)),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _order == null ? _buildSearchState() : _buildResultState(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            border: Border.all(color: const Color(0x26FFFFFF), width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.package, size: 16, color: AppColors.inkMuted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() { _id = v; _error = ""; }),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    hintText: "Enter your Order ID...",
                    hintStyle: TextStyle(fontSize: 14, color: AppColors.inkFaint),
                  ),
                  cursorColor: const Color(0xFF2EE6C5),
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        if (_error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(LucideIcons.alertCircle, size: 14, color: Color(0xFFFF6B6B)),
                const SizedBox(width: 6),
                Text(_error, style: const TextStyle(fontSize: 12, color: Color(0xFFFF6B6B))),
              ],
            ),
          ),
        GestureDetector(
          onTap: (_busy || _id.trim().isEmpty) ? null : _search,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2EE6C5).withValues(alpha: (_busy || _id.trim().isEmpty) ? 0.35 : 1.0),
              borderRadius: BorderRadius.circular(999),
              boxShadow: (_busy || _id.trim().isEmpty) ? null : const [
                BoxShadow(
                  color: Color(0x522EE6C5),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_busy) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF0F2027), strokeWidth: 2)) else const Icon(LucideIcons.search, size: 16, color: Color(0xFF0F2027)),
                const SizedBox(width: 8),
                Text(_busy ? "Searching..." : "Track Order", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F2027))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultState() {
    final status = _order!.status;
    Color bgColor = const Color(0x26FFD166);
    Color fgColor = const Color(0xFFFFD166);
    IconData icon = LucideIcons.loader;
    String title = "Pending Verification";
    String subtitle = "We are verifying your payment or order details.";

    if (status == "approved") {
      bgColor = const Color(0x262EE6A8);
      fgColor = const Color(0xFF2EE6A8);
      icon = LucideIcons.thumbsUp;
      title = "Order Approved! ✅";
      subtitle = "Your order is confirmed and will be delivered soon.";
    } else if (status == "rejected") {
      bgColor = const Color(0x26FF6B6B);
      fgColor = const Color(0xFFFF6B6B);
      icon = LucideIcons.thumbsDown;
      title = "Order Rejected";
      subtitle = "Your order was rejected or payment couldn't be verified.";
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: fgColor.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 36, color: fgColor),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: fgColor)),
              const SizedBox(height: 4),
              Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: fgColor.withValues(alpha: 0.85))),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            border: Border.all(color: const Color(0x26FFFFFF), width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Order Details", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.inkMuted)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("ID", style: TextStyle(fontSize: 14, color: AppColors.inkMuted)),
                  Text(_order!.id.substring(0, 8), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total", style: TextStyle(fontSize: 14, color: AppColors.inkMuted)),
                  Text("₹${_order!.total}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2EE6C5))),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Payment Method", style: TextStyle(fontSize: 14, color: AppColors.inkMuted)),
                  Text((_order!.paymentMethod ?? 'UNKNOWN').toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _order = null),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              border: Border.all(color: const Color(0x33FFFFFF), width: 1),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: const Text("Track Another", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
