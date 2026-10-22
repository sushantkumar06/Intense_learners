import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/payment/order_summary_modal.dart';
import '../../../components/payment/payment_method_modal.dart';
import '../../../components/payment/qr_payment_modal.dart';
import '../../../components/payment/track_order_modal.dart';
import '../../../components/safe_back_scope.dart';
import '../../../components/ui/ui.dart';
import '../../../models/payment.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_client.dart';
import '../../../services/cache_service.dart';
import '../../../theme/app_theme.dart';

const int minOrder = 200;

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  String _tab = "fees"; // "fees", "hardcopy", "cart"

  List<FeePlan> _feePlans = List.from(_curatedFeePlans);
  bool _plansLoading = false;
  String _selectedClass = "Class 12 (Science)";
  final Map<String, bool> _selectedPlans = {};

  List<PurchasableNote> _notes = List.from(_curatedPurchasableNotes);
  bool _notesLoading = false;
  String _noteSearch = "";
  final Map<String, int> _hardcopyQty = {};

  String _couponCode = "";
  Map<String, dynamic>? _appliedCoupon;
  String _couponError = "";
  bool _couponLoading = false;

  bool _showAddress = false;
  final AddressForm _address = AddressForm();

  bool _showMethodModal = false;
  bool _showSummaryModal = false;
  bool _showQrModal = false;
  bool _showTrackModal = false;

  String? _selectedMethod; // "qr" or "cod"
  PaymentOrderFull? _orderPlaced;
  bool _placingOrder = false;

  static final List<FeePlan> _curatedFeePlans = [
    FeePlan(id: "cls12-sci-pcm", classLevel: "Class 12 (Science)", subject: "PCM Bundle", price: 2400, originalPrice: 4197, duration: "1 Month", popular: true),
    FeePlan(id: "cls12-sci-phy", classLevel: "Class 12 (Science)", subject: "Physics", price: 900, originalPrice: 1399, duration: "1 Month", popular: false),
    FeePlan(id: "cls12-sci-chem", classLevel: "Class 12 (Science)", subject: "Chemistry", price: 900, originalPrice: 1399, duration: "1 Month", popular: false),
    FeePlan(id: "cls12-sci-math", classLevel: "Class 12 (Science)", subject: "Mathematics", price: 900, originalPrice: 1399, duration: "1 Month", popular: false),
    FeePlan(id: "cls10-all", classLevel: "Class 10", subject: "All Subjects", price: 2200, originalPrice: 3599, duration: "1 Month", popular: true),
    FeePlan(id: "cls10-math", classLevel: "Class 10", subject: "Mathematics", price: 600, originalPrice: 899, duration: "1 Month", popular: false),
    FeePlan(id: "cls10-sci", classLevel: "Class 10", subject: "Science", price: 600, originalPrice: 899, duration: "1 Month", popular: false),
    FeePlan(id: "jee-pcm", classLevel: "JEE", subject: "PCM Complete", price: 3500, originalPrice: 3900, duration: "1 Month", popular: true),
    FeePlan(id: "neet-pcb", classLevel: "NEET", subject: "PCB Complete", price: 3500, originalPrice: 3900, duration: "1 Month", popular: true),
  ];

  static final List<PurchasableNote> _curatedPurchasableNotes = [
    PurchasableNote(
      id: "note-pcm-12",
      title: "Class 12 Physics & Chemistry Formula Handbooks",
      description: "Spiral-bound, full-color printed edition with quick revision flashcards.",
      subject: "PCM",
      classLevel: "Class 12",
      fileName: "class12_pcm_handbook.pdf",
      fileType: "pdf",
      fileSize: "12.4 MB",
      thumbnailUrl: "https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400&q=80",
      isPinned: true,
      downloads: 145,
      views: 1200,
      price: 180,
      teacherName: "Prakash Jha",
    ),
    PurchasableNote(
      id: "note-calc-12",
      title: "Differential & Integral Calculus Problem Solver",
      description: "Class 12 CBSE & JEE standard stepwise solved problems notebook.",
      subject: "Mathematics",
      classLevel: "Class 12",
      fileName: "calculus_problem_solver.pdf",
      fileType: "pdf",
      fileSize: "8.6 MB",
      thumbnailUrl: "https://images.unsplash.com/photo-1509228468518-180dd4864904?w=400&q=80",
      isPinned: true,
      downloads: 98,
      views: 870,
      price: 150,
      teacherName: "Saqib Nadeem",
    ),
    PurchasableNote(
      id: "note-bio-neet",
      title: "NEET Biology High-Yield NCERT Diagram Atlas",
      description: "All 120+ NCERT diagrams annotated with previous year exam question pointers.",
      subject: "Biology",
      classLevel: "NEET",
      fileName: "neet_biology_diagrams.pdf",
      fileType: "pdf",
      fileSize: "15.1 MB",
      thumbnailUrl: "https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=400&q=80",
      isPinned: true,
      downloads: 210,
      views: 1890,
      price: 220,
      teacherName: "Dr. Anjali Verma",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _fetchData();
  }

  void _loadCachedData() {
    final cachedPlans = CacheService.getSync("cached_fee_plans_v1");
    if (cachedPlans is List && cachedPlans.isNotEmpty) {
      try {
        final plans = cachedPlans.map((e) => FeePlan.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        final classes = plans.map((p) => p.classLevel).toSet().toList();
        _feePlans = plans;
        if (classes.isNotEmpty) _selectedClass = classes.first;
        _plansLoading = false;
      } catch (e) {
        debugPrint("Error reading cached fee plans: $e");
        _feePlans = _curatedFeePlans;
        _selectedClass = _curatedFeePlans.first.classLevel;
        _plansLoading = false;
      }
    } else {
      _feePlans = _curatedFeePlans;
      _selectedClass = _curatedFeePlans.first.classLevel;
      _plansLoading = false;
    }
    final cachedNotes = CacheService.getSync("cached_purchasable_notes_v1");
    if (cachedNotes is List && cachedNotes.isNotEmpty) {
      try {
        _notes = cachedNotes.map((e) => PurchasableNote.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        _notesLoading = false;
      } catch (e) {
        debugPrint("Error reading cached purchasable notes: $e");
        _notes = _curatedPurchasableNotes;
        _notesLoading = false;
      }
    } else {
      _notes = _curatedPurchasableNotes;
      _notesLoading = false;
    }
  }

  Future<void> _fetchData() async {
    final dio = ref.read(dioProvider);

    // Fetch fee plans
    dio.get('/api/payments?action=fee-plans').then((response) {
      if (response.data != null && response.data['success'] == true && response.data['plans'] is List) {
        final list = response.data['plans'] as List;
        CacheService.set("cached_fee_plans_v1", list);
        final plans = list.map((e) => FeePlan.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        final classes = plans.map((p) => p.classLevel).toSet().toList();
        if (mounted) {
          setState(() {
            _feePlans = plans;
            if (classes.isNotEmpty && _selectedClass.isEmpty) _selectedClass = classes.first;
          });
        }
      }
    }).catchError((e) {
      debugPrint("Error fetching plans: $e");
    }).whenComplete(() {
      if (mounted) setState(() => _plansLoading = false);
    });

    // Fetch notes
    dio.get('/api/payments?action=notes').then((response) {
      if (response.data != null && response.data['success'] == true && response.data['notes'] is List) {
        final list = response.data['notes'] as List;
        CacheService.set("cached_purchasable_notes_v1", list);
        final parsed = list.map((e) => PurchasableNote.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        if (mounted) {
          setState(() {
            _notes = parsed;
          });
        }
      }
    }).catchError((e) {
      debugPrint("Error fetching notes: $e");
    }).whenComplete(() {
      if (mounted) setState(() => _notesLoading = false);
    });
  }

  Future<void> _handleConfirmOrder(num total, bool hasHardcopy, List<CartItem> cartItems) async {
    if (_selectedMethod == null) return;
    setState(() => _placingOrder = true);
    try {
      final dio = ref.read(dioProvider);
      final subtotal = cartItems.fold(0.0, (s, i) => s + i.price);
      final couponDiscount = _appliedCoupon?['discount'] as num? ?? 0;

      final response = await dio.post('/api/payments', data: {
        "action": "create-order",
        "items": cartItems.map((i) => i.toJson()).toList(),
        "subtotal": subtotal,
        "couponDiscount": couponDiscount,
        "total": total,
        "couponCode": _appliedCoupon?['code'],
        "address": hasHardcopy ? _address.toJson() : null,
        "paymentMethod": _selectedMethod,
        "userEmail": ref.read(authProvider).user?['email'],
      });

      if (response.data['success'] == true) {
        final order = PaymentOrderFull.fromJson(response.data['order']);
        setState(() {
          _orderPlaced = order;
          _showSummaryModal = false;
        });

        if (_selectedMethod == "cod") {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Order placed! You'll receive a confirmation.")),
            );
          }
          _resetCart();
        } else {
          setState(() => _showQrModal = true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['error'] ?? "Failed to place order")),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to place order")));
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  List<CartItem> get _cartItems {
    final items = <CartItem>[];

    // Fee plans
    for (final p in _feePlans) {
      if (_selectedPlans[p.id] == true) {
        items.add(CartItem(
          id: p.id,
          type: "fee",
          name: "${p.classLevel} · ${p.subject} (${p.duration})",
          price: p.price,
          subject: p.subject,
          classLevel: p.classLevel,
        ));
      }
    }

    // Hardcopy notes
    for (final entry in _hardcopyQty.entries) {
      if (entry.value > 0) {
        final noteId = entry.key;
        final qty = entry.value;
        final note = _notes.where((n) => n.id == noteId).firstOrNull;
        final unitPrice = note?.price ?? 30;
        items.add(CartItem(
          id: noteId,
          type: "hardcopy",
          name: note?.title ?? "Note",
          price: unitPrice * qty,
          qty: qty,
          unitPrice: unitPrice,
          subject: note?.subject,
        ));
      }
    }
    return items;
  }

  void _resetCart() {
    setState(() {
      _orderPlaced = null;
      _selectedMethod = null;
      _selectedPlans.clear();
      _hardcopyQty.clear();
      _appliedCoupon = null;
      _couponCode = "";
      _tab = "fees";
    });
  }

  Future<void> _handleApplyCoupon() async {
    if (_couponCode.trim().isEmpty) return;
    setState(() {
      _couponError = "";
      _couponLoading = true;
    });

    try {
      final dio = ref.read(dioProvider);
      final subtotal = _cartItems.fold(0.0, (s, i) => s + i.price);
      final response = await dio.post('/api/payments', data: {
        "action": "validate-coupon",
        "code": _couponCode,
        "subtotal": subtotal,
      });

      if (response.data['success'] == true) {
        setState(() {
          _appliedCoupon = {
            "code": response.data['code'],
            "discount": response.data['discount'],
            "label": response.data['label'],
          };
        });
      } else {
        setState(() => _couponError = response.data['error'] ?? "Invalid coupon");
      }
    } catch (_) {
      setState(() => _couponError = "Invalid coupon");
    } finally {
      if (mounted) setState(() => _couponLoading = false);
    }
  }

  void _handleProceedToPayment(num total, bool meetsMin, bool hasHardcopy) {
    if (_cartItems.isEmpty) return;
    if (!meetsMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Minimum order is ₹$minOrder. Add ₹${minOrder - total} more.")),
      );
      return;
    }
    if (hasHardcopy &&
        (_address.name.isEmpty ||
            _address.phone.isEmpty ||
            _address.address.isEmpty ||
            _address.city.isEmpty ||
            _address.pincode.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill complete delivery address.")),
      );
      setState(() => _showAddress = true);
      return;
    }
    setState(() => _showMethodModal = true);
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = _cartItems;
    final subtotal = cartItems.fold(0.0, (s, i) => s + i.price);
    final couponDiscount = _appliedCoupon?['discount'] as num? ?? 0;
    final total = (subtotal - couponDiscount) < 0 ? 0 : (subtotal - couponDiscount);
    final hasHardcopy = cartItems.any((i) => i.type == "hardcopy");
    final hasOnlyFees = cartItems.isNotEmpty && cartItems.every((i) => i.type == "fee");
    final meetsMin = total >= minOrder;

    return SafeBackScope(
      fallbackLocation: '/student/dashboard',
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(cartItems.length),
                  _buildTabs(cartItems.length),
                  if (cartItems.isNotEmpty && !meetsMin)
                    Container(
                      margin: const EdgeInsets.only(top: 12, left: AppSpacing.xl, right: AppSpacing.xl),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.goldTint,
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.alertTriangle, size: 15, color: AppColors.gold),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Minimum order ₹$minOrder. Add ₹${minOrder - total} more to proceed.',
                              style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: const Color(0xFF8A6816)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _buildTabContent(cartItems, subtotal, couponDiscount, total, hasHardcopy, meetsMin),
                  ),
                ],
              ),
            ),

            PaymentMethodModal(
              visible: _showMethodModal,
              total: total,
              showCod: hasHardcopy && !hasOnlyFees,
              onClose: () => setState(() => _showMethodModal = false),
              onSelect: (method) {
                setState(() {
                  _selectedMethod = method;
                  _showMethodModal = false;
                  _showSummaryModal = true;
                });
              },
            ),

            OrderSummaryModal(
              visible: _showSummaryModal,
              method: _selectedMethod,
              cartItems: cartItems,
              subtotal: subtotal,
              couponDiscount: couponDiscount,
              couponCode: _appliedCoupon?['code'],
              total: total,
              hasHardcopy: hasHardcopy,
              address: _address,
              submitting: _placingOrder,
              onClose: () => setState(() => _showSummaryModal = false),
              onConfirm: () => _handleConfirmOrder(total, hasHardcopy, cartItems),
            ),

            QRPaymentModal(
              visible: _showQrModal,
              order: _orderPlaced,
              onClose: () => setState(() => _showQrModal = false),
              onSuccess: () {
                setState(() => _showQrModal = false);
                _resetCart();
              },
            ),

            TrackOrderModal(
              visible: _showTrackModal,
              onClose: () => setState(() => _showTrackModal = false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int cartCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
              const SizedBox(width: AppSpacing.md),
              Text(
                "Fees & Payments",
                style: AppTypography.label.copyWith(fontSize: 15, color: AppColors.ink),
              ),
            ],
          ),
          Row(
            children: [
              AnimatedPressable(
                pressScale: 0.92,
                onPress: () => setState(() => _showTrackModal = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.mdBorder,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.truck, size: 13, color: AppColors.inkMuted),
                      const SizedBox(width: 5),
                      Text(
                        "Track",
                        style: AppTypography.label.copyWith(fontSize: 11.5, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedPressable(
                pressScale: 0.92,
                onPress: () => setState(() => _tab = "cart"),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: _tab == "cart" ? AppColors.indigo : AppColors.surface,
                    borderRadius: AppRadius.mdBorder,
                    border: _tab == "cart" ? null : Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.wallet,
                        size: 14,
                        color: _tab == "cart" ? Colors.white : AppColors.inkMuted,
                      ),
                      if (cartCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius: AppRadius.pillBorder,
                          ),
                          child: Text(
                            "$cartCount",
                            style: AppTypography.label.copyWith(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(int cartCount) {
    final tabs = [
      {'id': 'fees', 'label': 'Fees', 'icon': LucideIcons.graduationCap},
      {'id': 'hardcopy', 'label': 'Notes', 'icon': LucideIcons.printer},
      {'id': 'cart', 'label': cartCount > 0 ? 'Cart ($cartCount)' : 'Checkout', 'icon': LucideIcons.wallet},
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: tabs.map((t) {
          final active = _tab == t['id'];
          return Expanded(
            child: AnimatedPressable(
              pressScale: 0.97,
              onPress: () => setState(() => _tab = t['id'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? AppColors.indigo : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      size: 14,
                      color: active ? AppColors.indigo : AppColors.inkFaint,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t['label'] as String,
                      style: active
                          ? AppTypography.label.copyWith(fontSize: 12, color: AppColors.indigo)
                          : AppTypography.label.copyWith(fontSize: 12, color: AppColors.inkFaint),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(
    List<CartItem> cartItems,
    num subtotal,
    num couponDiscount,
    num total,
    bool hasHardcopy,
    bool meetsMin,
  ) {
    if (_tab == "fees") return _buildFeesTab();
    if (_tab == "hardcopy") return _buildHardcopyTab();
    return _buildCartTab(cartItems, subtotal, couponDiscount, total, hasHardcopy, meetsMin);
  }

  Widget _buildFeesTab() {
    final classes = _feePlans.map((p) => p.classLevel).toSet().toList();
    final plansForClass = _feePlans.where((p) => p.classLevel == _selectedClass).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(
          "Select Your Class",
          style: AppTypography.label.copyWith(fontSize: 14, color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_plansLoading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: AppColors.indigo)),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: classes.map((cls) {
                final active = _selectedClass == cls;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AnimatedPressable(
                    pressScale: 0.94,
                    onPress: () => setState(() => _selectedClass = cls),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? AppColors.indigo : AppColors.surface,
                        borderRadius: AppRadius.mdBorder,
                        border: active ? null : Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Text(
                        cls,
                        style: AppTypography.label.copyWith(
                          fontSize: 12.5,
                          color: active ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),

        if (_selectedClass.isNotEmpty)
          Text(
            "Plans for $_selectedClass",
            style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
          ),
        const SizedBox(height: AppSpacing.md),

        ...plansForClass.map((plan) {
          final isSelected = _selectedPlans[plan.id] == true;
          final save = plan.originalPrice - plan.price;
          final pct = ((save / plan.originalPrice) * 100).round();

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AnimatedPressable(
              pressScale: 0.98,
              onPress: () => setState(() => _selectedPlans[plan.id] = !isSelected),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.mdBorder,
                  border: Border.all(
                    color: isSelected ? AppColors.indigo : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.indigoTint,
                                borderRadius: AppRadius.smBorder,
                              ),
                              alignment: Alignment.center,
                              child: Icon(LucideIcons.graduationCap, size: 17, color: AppColors.indigo),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan.subject,
                                  style: AppTypography.label.copyWith(fontSize: 14, color: AppColors.ink),
                                ),
                                Text(
                                  plan.duration,
                                  style: AppTypography.body.copyWith(fontSize: 11.5, color: AppColors.inkMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "₹${plan.price}",
                              style: AppTypography.stat.copyWith(fontSize: 20, color: AppColors.ink),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "₹${plan.originalPrice}",
                              style: AppTypography.body.copyWith(
                                fontSize: 12,
                                color: AppColors.inkFaint,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        Row(
                          children: [
                            AppBadge(label: "$pct% OFF", tone: AppBadgeTone.success),
                            const SizedBox(width: 8),
                            Text(
                              "Save ₹$save",
                              style: AppTypography.caption.copyWith(fontSize: 10.5, color: AppColors.inkFaint),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.indigo : AppColors.surfaceMuted,
                            borderRadius: AppRadius.smBorder,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isSelected) ...[
                                const Icon(LucideIcons.check, size: 14, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  "Selected",
                                  style: AppTypography.label.copyWith(fontSize: 12, color: Colors.white),
                                ),
                              ] else ...[
                                Text(
                                  "Select",
                                  style: AppTypography.label.copyWith(fontSize: 12, color: AppColors.ink),
                                ),
                                const SizedBox(width: 6),
                                Icon(LucideIcons.arrowRight, size: 14, color: AppColors.ink),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (plan.popular)
                      const Positioned(
                        top: 0,
                        right: 0,
                        child: AppBadge(label: "★ Popular", tone: AppBadgeTone.gold),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHardcopyTab() {
    final filtered = _notes.where((n) {
      if (_noteSearch.trim().isEmpty) return true;
      final q = _noteSearch.toLowerCase();
      return n.title.toLowerCase().contains(q) || n.subject.toLowerCase().contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.goldTint,
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            borderRadius: AppRadius.mdBorder,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: AppRadius.smBorder,
                ),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.printer, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order Printed Notes",
                    style: AppTypography.label.copyWith(fontSize: 12, color: const Color(0xFF8A6816)),
                  ),
                  Text(
                    "Free delivery · 3–5 days",
                    style: AppTypography.body.copyWith(fontSize: 10.5, color: const Color(0xFF8A6816)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        AppInput(
          placeholder: "Search notes…",
          leftIcon: Icon(LucideIcons.search, size: 16, color: AppColors.inkFaint),
          onChanged: (v) => setState(() => _noteSearch = v),
        ),
        const SizedBox(height: AppSpacing.md),

        if (_notesLoading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: AppColors.indigo)),
          )
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                "No notes found",
                style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.inkMuted),
              ),
            ),
          )
        else
          ...filtered.map((note) {
            final qty = _hardcopyQty[note.id] ?? 0;
            final unitPrice = note.price > 0 ? note.price : 30;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.mdBorder,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: AppRadius.smBorder,
                      ),
                      alignment: Alignment.center,
                      clipBehavior: Clip.antiAlias,
                      child: note.thumbnailUrl != null
                          ? Image.network(note.thumbnailUrl!, width: 52, height: 52, cacheWidth: 104, cacheHeight: 104, fit: BoxFit.cover)
                          : Icon(LucideIcons.fileText, size: 20, color: AppColors.inkFaint),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${note.subject} · ${note.classLevel}",
                            style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "₹$unitPrice/copy",
                            style: AppTypography.label.copyWith(fontSize: 12.5, color: AppColors.ink),
                          ),
                        ],
                      ),
                    ),
                    if (qty == 0)
                      AnimatedPressable(
                        pressScale: 0.93,
                        onPress: () => setState(() => _hardcopyQty[note.id] = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.indigo,
                            borderRadius: AppRadius.smBorder,
                          ),
                          child: Text(
                            "Add",
                            style: AppTypography.label.copyWith(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          AnimatedPressable(
                            pressScale: 0.9,
                            onPress: () => setState(() {
                              if (_hardcopyQty[note.id]! <= 1) {
                                _hardcopyQty.remove(note.id);
                              } else {
                                _hardcopyQty[note.id] = _hardcopyQty[note.id]! - 1;
                              }
                            }),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: AppRadius.smBorder,
                              ),
                              alignment: Alignment.center,
                              child: Icon(LucideIcons.minus, size: 14, color: AppColors.ink),
                            ),
                          ),
                          SizedBox(
                            width: 26,
                            child: Text(
                              "$qty",
                              textAlign: TextAlign.center,
                              style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
                            ),
                          ),
                          AnimatedPressable(
                            pressScale: 0.9,
                            onPress: () => setState(() => _hardcopyQty[note.id] = qty + 1),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.indigo,
                                borderRadius: AppRadius.smBorder,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCartTab(
    List<CartItem> cartItems,
    num subtotal,
    num couponDiscount,
    num total,
    bool hasHardcopy,
    bool meetsMin,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        // Cart Items Box
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                color: AppColors.surfaceMuted,
                width: double.infinity,
                child: Text(
                  "Cart (${cartItems.length} items)",
                  style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
                ),
              ),
              if (cartItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        "Your cart is empty",
                        style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.inkMuted),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: "Browse Plans",
                        size: AppButtonSize.sm,
                        onPress: () => setState(() => _tab = "fees"),
                      ),
                    ],
                  ),
                )
              else
                ...cartItems.map((item) {
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${item.name}${item.qty != null ? ' × ${item.qty}' : ''}",
                                style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.ink),
                              ),
                              if (item.qty != null && item.unitPrice != null)
                                Text(
                                  "₹${item.unitPrice} × ${item.qty}",
                                  style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          "₹${item.price}",
                          style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Delivery Address Accordion (if hardcopy)
        if (hasHardcopy && cartItems.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                AnimatedPressable(
                  pressScale: 0.99,
                  onPress: () => setState(() => _showAddress = !_showAddress),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Delivery Address",
                            style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
                          ),
                          if (!_showAddress && _address.name.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              "✓ Filled",
                              style: AppTypography.label.copyWith(fontSize: 11, color: AppColors.mint),
                            ),
                          ],
                        ],
                      ),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: _showAddress ? 0.5 : 0.0,
                        child: Icon(LucideIcons.chevronDown, size: 16, color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                if (_showAddress) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildAddressField("Full Name", _address.name, (v) => setState(() => _address.name = v)),
                  const SizedBox(height: 8),
                  _buildAddressField("Phone", _address.phone, (v) => setState(() => _address.phone = v),
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 8),
                  _buildAddressField("Full Address", _address.address, (v) => setState(() => _address.address = v)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAddressField("City", _address.city, (v) => setState(() => _address.city = v)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAddressField(
                            "PIN Code", _address.pincode, (v) => setState(() => _address.pincode = v),
                            keyboardType: TextInputType.number),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Coupon Card
        if (cartItems.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.tag, size: 14, color: AppColors.indigo),
                    const SizedBox(width: 6),
                    Text(
                      "Coupon Code",
                      style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.ink),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (_appliedCoupon != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.mintTint,
                      border: Border.all(color: AppColors.mint.withValues(alpha: 0.4)),
                      borderRadius: AppRadius.mdBorder,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${_appliedCoupon!['code']}",
                              style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.mint),
                            ),
                            Text(
                              "${_appliedCoupon!['label']} · Saved ₹${_appliedCoupon!['discount']}",
                              style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.mint),
                            ),
                          ],
                        ),
                        AnimatedPressable(
                          pressScale: 0.85,
                          onPress: () => setState(() {
                            _appliedCoupon = null;
                            _couponCode = "";
                          }),
                          child: Icon(LucideIcons.x, size: 16, color: AppColors.coral),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0x1FFFFFFF),
                                Color(0x0DFFFFFF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x33FFFFFF), width: 1.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F000000),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: TextEditingController(text: _couponCode)
                              ..selection = TextSelection.collapsed(offset: _couponCode.length),
                            textCapitalization: TextCapitalization.characters,
                            cursorColor: const Color(0xFF2EE6C5),
                            style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.ink),
                            decoration: InputDecoration(
                              hintText: "Enter code",
                              hintStyle: AppTypography.body.copyWith(color: AppColors.inkFaint, fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                            onChanged: (v) {
                              _couponCode = v.toUpperCase();
                              _couponError = "";
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedPressable(
                        pressScale: 0.93,
                        onPress: (_couponLoading || _couponCode.trim().isEmpty) ? null : _handleApplyCoupon,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          decoration: BoxDecoration(
                            color: AppColors.indigo,
                            borderRadius: AppRadius.mdBorder,
                          ),
                          child: _couponLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Row(
                                  children: [
                                    const Icon(LucideIcons.tag, size: 14, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Apply",
                                      style: AppTypography.label.copyWith(fontSize: 12, color: Colors.white),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                if (_couponError.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _couponError,
                    style: AppTypography.caption.copyWith(color: AppColors.coral),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Order Summary
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order Summary",
                  style: AppTypography.label.copyWith(fontSize: 14, color: AppColors.ink),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Subtotal", style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.inkMuted)),
                    Text("₹$subtotal", style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.inkMuted)),
                  ],
                ),
                if (couponDiscount > 0) ...[
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Discount", style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.mint)),
                      Text("-₹$couponDiscount",
                          style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.mint)),
                    ],
                  ),
                ],
                if (hasHardcopy) ...[
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Delivery", style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.inkMuted)),
                      Text("FREE", style: AppTypography.label.copyWith(fontSize: 13, color: AppColors.mint)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total", style: AppTypography.label.copyWith(fontSize: 14.5, color: AppColors.ink)),
                    Text("₹$total", style: AppTypography.label.copyWith(fontSize: 14.5, color: AppColors.indigo)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                AppButton(
                  label: "Proceed to Payment",
                  icon: LucideIcons.lock,
                  fullWidth: true,
                  size: AppButtonSize.lg,
                  disabled: !meetsMin,
                  onPress: () => _handleProceedToPayment(total, meetsMin, hasHardcopy),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAddressField(
    String hint,
    String value,
    Function(String) onChanged, {
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x1FFFFFFF),
            Color(0x0DFFFFFF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33FFFFFF), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        keyboardType: keyboardType,
        cursorColor: const Color(0xFF2EE6C5),
        style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.body.copyWith(color: AppColors.inkFaint, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }
}
