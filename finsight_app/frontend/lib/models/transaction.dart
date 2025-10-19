class Transaction {
  final int? id;
  final String merchant;
  final double amount;
  final String category;
  final DateTime date;
  final String? description;
  final bool isManual;
  final bool isUncategorized;
  final String? type;

  Transaction({
    this.id,
    required this.merchant,
    required this.amount,
    required this.category,
    required this.date,
    this.description,
    this.isManual = false,
    this.isUncategorized = false,
    this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'description': description,
      'isManual': isManual ? 1 : 0,
      'isUncategorized': isUncategorized ? 1 : 0,
      'type': type,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      merchant: map['merchant'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String?,
      isManual: (map['isManual'] as int?) == 1,
      isUncategorized: (map['isUncategorized'] as int?) == 1,
      type: map['type'] as String?,
    );
  }

  Transaction copyWith({
    int? id,
    String? merchant,
    double? amount,
    String? category,
    DateTime? date,
    String? description,
    bool? isManual,
    bool? isUncategorized,
    String? type,
  }) {
    return Transaction(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      isManual: isManual ?? this.isManual,
      isUncategorized: isUncategorized ?? this.isUncategorized,
      type: type ?? this.type,
    );
  }

  @override
  String toString() {
    return 'Transaction{id: $id, merchant: $merchant, amount: $amount, category: $category, date: $date, type: $type}';
  }
}
