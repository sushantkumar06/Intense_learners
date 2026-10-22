class FeePlan {
  final String id;
  final String classLevel; // 'class' in JS
  final String subject;
  final num price;
  final num originalPrice;
  final String duration;
  final bool popular;

  FeePlan({
    required this.id,
    required this.classLevel,
    required this.subject,
    required this.price,
    required this.originalPrice,
    required this.duration,
    required this.popular,
  });

  factory FeePlan.fromJson(Map<String, dynamic> json) {
    return FeePlan(
      id: json['id']?.toString() ?? '',
      classLevel: (json['class'] ?? json['classLevel'])?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      price: json['price'] as num? ?? 0,
      originalPrice: json['originalPrice'] as num? ?? 0,
      duration: json['duration']?.toString() ?? '1 Month',
      popular: json['popular'] == true,
    );
  }
}

class PurchasableNote {
  final String id;
  final String title;
  final String? description;
  final String subject;
  final String classLevel;
  final String? topic;
  final String? chapter;
  final String fileName;
  final String fileType;
  final String fileSize;
  final String? thumbnailUrl;
  final bool isPinned;
  final int downloads;
  final int views;
  final num price;
  final String? teacherName;
  final String? teacherAvatar;

  PurchasableNote({
    required this.id,
    required this.title,
    this.description,
    required this.subject,
    required this.classLevel,
    this.topic,
    this.chapter,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    this.thumbnailUrl,
    required this.isPinned,
    required this.downloads,
    required this.views,
    required this.price,
    this.teacherName,
    this.teacherAvatar,
  });

  factory PurchasableNote.fromJson(Map<String, dynamic> json) {
    final rawTeacher = json['teacher'];
    final teacher = rawTeacher is Map ? Map<String, dynamic>.from(rawTeacher) : null;
    return PurchasableNote(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      subject: json['subject']?.toString() ?? '',
      classLevel: (json['class'] ?? json['classLevel'])?.toString() ?? '',
      topic: json['topic']?.toString(),
      chapter: json['chapter']?.toString(),
      fileName: json['fileName']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? '',
      fileSize: json['fileSize']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      isPinned: json['isPinned'] == true,
      downloads: (json['downloads'] as num?)?.toInt() ?? 0,
      views: (json['views'] as num?)?.toInt() ?? 0,
      price: json['price'] as num? ?? 0,
      teacherName: teacher?['name']?.toString(),
      teacherAvatar: teacher?['avatar']?.toString(),
    );
  }
}

class CartItem {
  final String id;
  final String type; // "fee" | "hardcopy"
  final String name;
  final num price;
  final int? qty;
  final String? subject;
  final String? classLevel;
  final num? unitPrice;

  CartItem({
    required this.id,
    required this.type,
    required this.name,
    required this.price,
    this.qty,
    this.subject,
    this.classLevel,
    this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'price': price,
      if (qty != null) 'qty': qty,
      if (subject != null) 'subject': subject,
      if (classLevel != null) 'class': classLevel,
      if (unitPrice != null) 'unitPrice': unitPrice,
    };
  }
}

class AddressForm {
  String name;
  String phone;
  String email;
  String address;
  String city;
  String state;
  String pincode;
  String? landmark;

  AddressForm({
    this.name = "",
    this.phone = "",
    this.email = "",
    this.address = "",
    this.city = "",
    this.state = "",
    this.pincode = "",
    this.landmark,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      if (landmark != null) 'landmark': landmark,
    };
  }
}

class PaymentOrderFull {
  final String id;
  final List<CartItem> items;
  final AddressForm? address;
  final num subtotal;
  final num couponDiscount;
  final num total;
  final String? couponCode;
  final String? paymentMethod;
  final String status;
  final String createdAt;

  PaymentOrderFull({
    required this.id,
    required this.items,
    this.address,
    required this.subtotal,
    required this.couponDiscount,
    required this.total,
    this.couponCode,
    this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  factory PaymentOrderFull.fromJson(Map<String, dynamic> json) {
    return PaymentOrderFull(
      id: json['id']?.toString() ?? '',
      items: (json['items'] as List<dynamic>?)?.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return CartItem(
          id: m['id']?.toString() ?? '',
          type: m['type']?.toString() ?? 'fee',
          name: m['name']?.toString() ?? '',
          price: m['price'] as num? ?? 0,
          qty: (m['qty'] as num?)?.toInt(),
          subject: m['subject']?.toString(),
          classLevel: (m['class'] ?? m['classLevel'])?.toString(),
          unitPrice: m['unitPrice'] as num?,
        );
      }).toList() ?? [],
      address: null, // Depending on if we need to parse it back from server
      subtotal: json['subtotal'] as num? ?? 0,
      couponDiscount: json['couponDiscount'] as num? ?? 0,
      total: json['total'] as num? ?? 0,
      couponCode: json['couponCode']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
