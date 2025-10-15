import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/sms_parser_service.dart';
import '../services/sms_ml_service.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastSyncDate;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastSyncDate => _lastSyncDate;

  Future<void> loadTransactions() async {
    _setLoading(true);
    try {
      _transactions = await DatabaseService.getAllTransactions();
      _lastSyncDate = await DatabaseService.getLatestTransactionDate();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      final id = await DatabaseService.insertTransaction(transaction);
      if (id != -1) {
        _transactions.insert(0, transaction.copyWith(id: id));
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await DatabaseService.updateTransaction(transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await DatabaseService.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> syncSMSData() async {
    _setLoading(true);
    try {
      await SMSMLService.initialize();
      List<Transaction> smsTransactions =
          await SMSParserService.parseSMSMessages();
      smsTransactions =
          await SMSParserService.categorizeTransactions(smsTransactions);

      if (_lastSyncDate != null) {
        smsTransactions = smsTransactions
            .where((t) => t.date.isAfter(_lastSyncDate!))
            .toList();
        print('📊 Found ${smsTransactions.length} new SMS since last sync');
      }

      final insertedCount =
          await DatabaseService.insertTransactionsBatch(smsTransactions);
      print('✅ Added $insertedCount new transactions');

      await loadTransactions();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Map<String, double> getMonthlySpendingByCategory(DateTime month) {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 1);

    final Map<String, double> categorySpending = {};

    for (final transaction in _transactions) {
      if (transaction.date
              .isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          transaction.date.isBefore(endDate)) {
        categorySpending[transaction.category] =
            (categorySpending[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return categorySpending;
  }

  double getTotalSpendingForMonth(DateTime month) {
    final spending = getMonthlySpendingByCategory(month);
    return spending.values.fold<double>(0.0, (sum, amount) => sum + amount);
  }

  List<Transaction> getTransactionsForMonth(DateTime month) {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 1);

    return _transactions
        .where((t) =>
            t.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(endDate))
        .toList();
  }

  List<Map<String, dynamic>> getDailySpendingData(int days) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final Map<String, double> dailySpending = {};

    for (final transaction in _transactions) {
      if (transaction.date.isAfter(startDate) &&
          transaction.date.isBefore(endDate.add(const Duration(days: 1)))) {
        final dateKey =
            '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}-${transaction.date.day.toString().padLeft(2, '0')}';
        dailySpending[dateKey] =
            (dailySpending[dateKey] ?? 0) + transaction.amount;
      }
    }

    return dailySpending.entries
        .map((e) => {'date': e.key, 'amount': e.value})
        .toList();
  }

  Map<String, double> getAverageSpendingByCategory(int months) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months, 1);

    final Map<String, List<double>> categoryAmounts = {};

    for (final transaction in _transactions) {
      if (transaction.date.isAfter(startDate)) {
        categoryAmounts
            .putIfAbsent(transaction.category, () => [])
            .add(transaction.amount);
      }
    }

    final Map<String, double> averageSpending = {};
    categoryAmounts.forEach((category, amounts) {
      averageSpending[category] =
          amounts.reduce((a, b) => a + b) / amounts.length;
    });

    return averageSpending;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
