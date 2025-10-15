class Transaction {
  final int? id;
  final String merchant;
  final double amount;
  final String category;
  final DateTime date;
  final String? description;
  final bool isManual;
  final bool isUncategorized;

  Transaction({
    this.id,
    required this.merchant,
    required this.amount,
    required this.category,
    required this.date,
    this.description,
    this.isManual = false,
    this.isUncategorized = false,
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
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      merchant: map['merchant'],
      amount: map['amount'],
      category: map['category'],
      date: DateTime.parse(map['date']),
      description: map['description'],
      isManual: map['isManual'] == 1,
      isUncategorized: map['isUncategorized'] == 1,
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
    );
  }
}
