class Invoice {
  const Invoice({
    this.id,
    required this.customerName,
    required this.amount,
    required this.createdAt,
    this.notes = '',
  });

  final int? id;
  final String customerName;
  final double amount;
  final DateTime createdAt;
  final String notes;

  Invoice copyWith({
    int? id,
    String? customerName,
    double? amount,
    DateTime? createdAt,
    String? notes,
  }) {
    return Invoice(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'customer_name': customerName,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory Invoice.fromMap(Map<String, Object?> map) {
    return Invoice(
      id: map['id'] as int?,
      customerName: map['customer_name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      notes: map['notes'] as String? ?? '',
    );
  }
}
