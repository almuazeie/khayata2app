class Customer {
  final String name;
  final String phone;
  final String invoiceNumber;
  final DateTime createdAt;

  Customer({
    required this.name,
    required this.phone,
    required this.invoiceNumber,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      name: json['name'] as String,
      phone: json['phone'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'invoiceNumber': invoiceNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}