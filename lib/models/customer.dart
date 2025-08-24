class Customer {
  final String name;
  final String phone;
  final String invoiceNumber;
  final DateTime createdAt;

  const Customer({
    required this.name,
    required this.phone,
    required this.invoiceNumber,
    required this.createdAt,
  });

  /// مُنشئ مساعد يضمن تنظيف القيم من المسافات
  factory Customer.create({
    required String name,
    required String phone,
    required String invoiceNumber,
    DateTime? createdAt,
  }) {
    return Customer(
      name: name.trim(),
      phone: phone.trim(),
      invoiceNumber: invoiceNumber.trim(),
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// fromJson متسامح: يتعامل مع نقص أو فساد createdAt
  factory Customer.fromJson(Map<String, dynamic> json) {
    final createdRaw = (json['createdAt'] ?? '').toString();
    final parsed = DateTime.tryParse(createdRaw);

    return Customer(
      name: (json['name'] ?? '').toString().trim(),
      phone: (json['phone'] ?? '').toString().trim(),
      invoiceNumber: (json['invoiceNumber'] ?? '').toString().trim(),
      createdAt: parsed ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'invoiceNumber': invoiceNumber,
    'createdAt': createdAt.toIso8601String(),
  };

  /// نسخ مع تعديل
  Customer copyWith({
    String? name,
    String? phone,
    String? invoiceNumber,
    DateTime? createdAt,
  }) {
    return Customer(
      name: name?.trim() ?? this.name,
      phone: phone?.trim() ?? this.phone,
      invoiceNumber: invoiceNumber?.trim() ?? this.invoiceNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// للمقارنة في القوائم/الاختبارات
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer &&
        other.name == name &&
        other.phone == phone &&
        other.invoiceNumber == invoiceNumber &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      name.hashCode ^ phone.hashCode ^ invoiceNumber.hashCode ^ createdAt.hashCode;

  @override
  String toString() =>
      'Customer(name: $name, phone: $phone, invoice: $invoiceNumber, createdAt: $createdAt)';

  /// عوامل فرز جاهزة
  static int sortByNewest(Customer a, Customer b) => b.createdAt.compareTo(a.createdAt);
  static int sortByOldest(Customer a, Customer b) => a.createdAt.compareTo(b.createdAt);
}