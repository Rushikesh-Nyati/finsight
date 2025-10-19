import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/sms_parser_service.dart';
import 'package:telephony/telephony.dart';

class TransactionProvider with ChangeNotifier {
  final Telephony _telephony = Telephony.instance;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TransactionProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    await loadTransactions();
  }

  Future<void> syncSMSTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('\n🚀 ===== SMS SYNC STARTED =====');

      final hasPermission = await _telephony.requestPhoneAndSmsPermissions;
      if (hasPermission != true) {
        _error = 'SMS permission denied';
        _isLoading = false;
        notifyListeners();
        debugPrint('❌ Permission denied');
        return;
      }

      debugPrint('✅ Permission granted');

      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final startMillis = currentMonthStart.millisecondsSinceEpoch;
      final endMillis = currentMonthEnd.millisecondsSinceEpoch;

      debugPrint(
          '📅 Filtering for current month: ${DateFormat('MMMM yyyy').format(now)}');
      debugPrint('📅 Range: $currentMonthStart to $currentMonthEnd');
      debugPrint('📥 Fetching SMS messages from current month only...');

      final List<SmsMessage> messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.DATE)
            .greaterThanOrEqualTo(startMillis.toString())
            .and(SmsColumn.DATE)
            .lessThanOrEqualTo(endMillis.toString()),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      debugPrint('📨 Total SMS found in current month: ${messages.length}');

      int acceptedCount = 0;
      int rejectedCount = 0;
      int parsedCount = 0;
      int duplicateCount = 0;
      int dateFixedCount = 0;
      int smartDuplicateCount = 0;

      List<Transaction> allTransactions =
          await DatabaseService.getAllTransactions();

      debugPrint('🔍 Processing messages...\n');

      for (final sms in messages) {
        final sender = sms.address ?? '';
        final body = sms.body ?? '';

        final smsTimestamp = sms.date != null
            ? DateTime.fromMillisecondsSinceEpoch(sms.date!)
            : DateTime.now();

        if (SmsParserService.isTransactionSMS(sender, body)) {
          acceptedCount++;

          final transactionData =
              SmsParserService.parseTransaction(sender, body);

          if (transactionData != null) {
            DateTime transactionDate = transactionData['date'] as DateTime;

            final today = DateTime.now();
            final parsedIsToday = transactionDate.year == today.year &&
                transactionDate.month == today.month &&
                transactionDate.day == today.day;

            if (parsedIsToday &&
                smsTimestamp
                    .isBefore(today.subtract(const Duration(hours: 1)))) {
              transactionDate = smsTimestamp;
              dateFixedCount++;
              debugPrint(
                  '📅 Fixed date using SMS timestamp: ${DateFormat('dd/MM/yyyy').format(transactionDate)}');
            }

            final amount = transactionData['amount'] as double;
            final type = transactionData['type'] as String?;
            final merchant = transactionData['merchant'] as String;

            bool isDuplicate = false;

            if (allTransactions.any((t) => t.description == body)) {
              duplicateCount++;
              isDuplicate = true;
              debugPrint('⚠️ Exact SMS duplicate detected, skipping...');
            } else {
              for (final existingTxn in allTransactions) {
                final amountMatch = (existingTxn.amount - amount).abs() < 0.01;
                final dateDiff =
                    existingTxn.date.difference(transactionDate).inHours.abs();
                final dateMatch = dateDiff <= 24;
                final typeMatch = existingTxn.type == type;

                if (amountMatch && dateMatch && typeMatch) {
                  smartDuplicateCount++;
                  isDuplicate = true;
                  debugPrint('🔍 Smart duplicate detected:');
                  debugPrint(
                      '   Existing: ${existingTxn.type?.toUpperCase()} ₹${existingTxn.amount} on ${DateFormat('dd/MM/yyyy').format(existingTxn.date)} - ${existingTxn.merchant}');
                  debugPrint(
                      '   New: ${type?.toUpperCase()} ₹$amount on ${DateFormat('dd/MM/yyyy').format(transactionDate)} - $merchant');
                  debugPrint('   ⚠️ Skipping to avoid duplicate...');
                  break;
                }
              }
            }

            if (isDuplicate) {
              continue;
            }

            final category = SmsParserService.categorizeTransaction(
              merchant,
              body,
            );

            final transaction = Transaction(
              amount: amount,
              category: category,
              description: body,
              date: transactionDate,
              merchant: merchant,
              type: type,
              isManual: false,
              isUncategorized: category == 'Uncategorized',
            );

            await DatabaseService.insertTransaction(transaction);
            allTransactions.add(transaction);
            parsedCount++;
            debugPrint(
                '✅ Saved: ${transaction.type?.toUpperCase()} ₹${transaction.amount} on ${DateFormat('dd/MM/yyyy').format(transactionDate)} - $category');
          }
        } else {
          rejectedCount++;
        }
      }

      await loadTransactions();

      debugPrint('\n📊 ===== SMS SYNC COMPLETE =====');
      debugPrint('📨 Total SMS scanned: ${messages.length}');
      debugPrint('✅ Transaction SMS: $acceptedCount');
      debugPrint('❌ Rejected (promo/OTP): $rejectedCount');
      debugPrint('📅 Dates fixed: $dateFixedCount');
      debugPrint('🔄 Exact duplicates: $duplicateCount');
      debugPrint('🔍 Smart duplicates: $smartDuplicateCount');
      debugPrint('💾 New transactions saved: $parsedCount');
      debugPrint('📱 Total in app: ${_transactions.length}');
      debugPrint('================================\n');

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      _error = 'Error syncing SMS: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ SMS Sync Error: $e');
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  Future<void> loadTransactions() async {
    try {
      _transactions = await DatabaseService.getAllTransactions();
      debugPrint('📊 Loaded ${_transactions.length} transactions from DB');
      notifyListeners();
    } catch (e) {
      _error = 'Error loading transactions: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      await DatabaseService.insertTransaction(transaction);
      await loadTransactions();
    } catch (e) {
      _error = 'Error adding transaction: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await DatabaseService.updateTransaction(transaction);
      await loadTransactions();
    } catch (e) {
      _error = 'Error updating transaction: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await DatabaseService.deleteTransaction(id);
      await loadTransactions();
    } catch (e) {
      _error = 'Error deleting transaction: ${e.toString()}';
      notifyListeners();
    }
  }

  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _transactions.where((t) {
      return t.date.isAfter(start.subtract(const Duration(days: 1))) &&
          t.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // ✅ FIXED: Only count debits for category spending
  Map<String, double> getMonthlySpendingByCategory() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final monthlyTransactions =
        getTransactionsByDateRange(startOfMonth, endOfMonth);

    final Map<String, double> categorySpending = {};
    for (final transaction in monthlyTransactions) {
      if (transaction.type == 'debit') {
        categorySpending[transaction.category] =
            (categorySpending[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return categorySpending;
  }

  // ✅ FIXED: Calculate as debits - credits
  double getTotalMonthlySpending() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final monthlyTransactions =
        getTransactionsByDateRange(startOfMonth, endOfMonth);

    double totalDebits = 0.0;
    double totalCredits = 0.0;

    for (final transaction in monthlyTransactions) {
      if (transaction.type == 'debit') {
        totalDebits += transaction.amount;
      } else if (transaction.type == 'credit') {
        totalCredits += transaction.amount;
      }
    }

    return totalDebits - totalCredits;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
