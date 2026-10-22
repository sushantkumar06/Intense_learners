import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/payment.dart';
import '../../theme/app_theme.dart';

class OrderSummaryModal extends StatelessWidget {
  final bool visible;
  final String? method; // "qr" or "cod"
  final List<CartItem> cartItems;
  final num subtotal;
  final num couponDiscount;
  final String? couponCode;
  final num total;
  final bool hasHardcopy;
  final AddressForm address;
  final bool submitting;
  final VoidCallback onClose;
  final VoidCallback onConfirm;

  const OrderSummaryModal({
    super.key,
    required this.visible,
    required this.method,
    required this.cartItems,
    required this.subtotal,
    required this.couponDiscount,
    required this.couponCode,
    required this.total,
    required this.hasHardcopy,
    required this.address,
    required this.submitting,
    required this.onClose,
    required this.onConfirm,
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
              onTap: submitting ? null : onClose,
              child: Container(color: Colors.black.withValues(alpha: 0.7)),
            ),
          ),
          AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, 1),
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
                    boxShadow: kGlassCardShadow,
                    border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
                  ),
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
                  child: method == null ? const SizedBox() : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Confirm Order", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            GestureDetector(
                              onTap: submitting ? null : onClose,
                              child: const Icon(LucideIcons.x, size: 22, color: AppColors.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0x1AFFFFFF)),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0x14FFFFFF),
                                  border: Border.all(color: const Color(0x402EE6C5), width: 1.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0x262EE6C5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(method == "qr" ? LucideIcons.qrCode : LucideIcons.banknote, size: 20, color: const Color(0xFF2EE6C5)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(method == "qr" ? "QR Code Payment" : "Cash on Delivery", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                          Text(method == "qr" ? "Pay via UPI by scanning QR code" : "Pay when you receive the order", style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0x14FFFFFF),
                                  border: Border.all(color: const Color(0x26FFFFFF), width: 1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: const BoxDecoration(
                                        color: Color(0x0FFFFFFF),
                                        border: Border(bottom: BorderSide(color: Color(0x1FFFFFFF))),
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                      ),
                                      child: const Text("Order Summary", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        children: [
                                          ...cartItems.map((item) => Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(child: Text("${item.name}${item.qty != null ? ' × ${item.qty}' : ''}", style: const TextStyle(fontSize: 14, color: AppColors.inkMuted))),
                                                Text("₹${item.price}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                                              ],
                                            ),
                                          )),
                                          const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1, color: Color(0x1FFFFFFF))),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text("Subtotal", style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                                              Text("₹$subtotal", style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                                            ],
                                          ),
                                          if (couponDiscount > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text("Discount ($couponCode)", style: const TextStyle(fontSize: 12, color: Color(0xFF2EE6C5))),
                                                  Text("-₹$couponDiscount", style: const TextStyle(fontSize: 12, color: Color(0xFF2EE6C5))),
                                                ],
                                              ),
                                            ),
                                          if (hasHardcopy)
                                            const Padding(
                                              padding: EdgeInsets.only(top: 4),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text("Delivery", style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                                                  Text("FREE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF2EE6C5))),
                                                ],
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text("Total", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                              Text("₹$total", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2EE6C5))),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (hasHardcopy)
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0x14FFFFFF),
                                    border: Border.all(color: const Color(0x26FFFFFF), width: 1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Delivery Address", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                      const SizedBox(height: 8),
                                      Text(address.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                                      Text(address.phone, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                                      Text("${address.address}, ${address.city}, ${address.state} ${address.pincode}", style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                                    ],
                                  ),
                                ),
                              ElevatedButton(
                                onPressed: submitting ? null : onConfirm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2EE6C5),
                                  foregroundColor: const Color(0xFF0F2027),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: const StadiumBorder(),
                                  elevation: 0,
                                  shadowColor: const Color(0x522EE6C5),
                                ),
                                child: submitting 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF0F2027), strokeWidth: 2))
                                  : Text(method == "qr" ? "Place Order & Pay" : "Confirm Order", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F2027))),
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
