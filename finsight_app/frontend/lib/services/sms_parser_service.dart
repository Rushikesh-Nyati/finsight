import 'package:telephony/telephony.dart';
import '../models/transaction.dart';
import 'sms_ml_service.dart';

class SMSParserService {
  static final RegExp _amountRegex = RegExp(r'[₹$]?(\d+(?:\.\d{2})?)');
  static final RegExp _debitRegex =
      RegExp(r'(?:debited|spent|paid|withdrawn)', caseSensitive: false);
  static final RegExp _creditRegex =
      RegExp(r'(?:credited|received|deposited)', caseSensitive: false);

  static Future<List<Transaction>> parseSMSMessages() async {
    try {
      final Telephony telephony = Telephony.instance;
      final List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      List<Transaction> transactions = [];
      for (SmsMessage message in messages.take(1000)) {
        final transaction = _parseSMSMessage(message);
        if (transaction != null) {
          transactions.add(transaction);
        }
      }
      return transactions;
    } catch (e) {
      print('Error parsing SMS messages: $e');
      return [];
    }
  }

  static Transaction? _parseSMSMessage(SmsMessage message) {
    final body = message.body ?? '';

    if (!_isFinancialSMS(body)) {
      return null;
    }

    final amountMatch = _amountRegex.firstMatch(body);
    if (amountMatch == null) return null;

    final amount = double.tryParse(amountMatch.group(1) ?? '0');
    if (amount == null || amount <= 0) return null;

    final isDebit = _debitRegex.hasMatch(body);
    final isCredit = _creditRegex.hasMatch(body);
    if (!isDebit && !isCredit) return null;

    final merchant = _extractMerchant(body);

    // FIXED: Convert int timestamp to DateTime
    final DateTime messageDate = message.date != null
        ? DateTime.fromMillisecondsSinceEpoch(message.date as int)
        : DateTime.now();

    return Transaction(
      merchant: merchant,
      amount: isDebit ? amount : -amount,
      category: 'Uncategorized',
      date: messageDate, // Use converted DateTime
      description: body,
      isManual: false,
      isUncategorized: true,
    );
  }

  static bool _isFinancialSMS(String body) {
    final financialKeywords = [
      'debited',
      'credited',
      'spent',
      'paid',
      'received',
      'deposited',
      'withdrawn',
      'balance',
      'account',
      'transaction',
      'payment',
      'upi',
      'imps',
      'neft',
      'rtgs',
      'atm',
      'pos',
      'card'
    ];
    final lowerBody = body.toLowerCase();
    return financialKeywords.any((keyword) => lowerBody.contains(keyword));
  }

  static String _extractMerchant(String body) {
    final patterns = [
      RegExp(r'at\s+([A-Za-z\s]+?)(?:\s|$)', caseSensitive: false),
      RegExp(r'to\s+([A-Za-z\s]+?)(?:\s|$)', caseSensitive: false),
      RegExp(r'from\s+([A-Za-z\s]+?)(?:\s|$)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final merchant = match.group(1)?.trim();
        if (merchant != null && merchant.isNotEmpty) {
          return merchant;
        }
      }
    }

    final words = body.split(' ');
    for (int i = 0; i < words.length - 1; i++) {
      final word = words[i].toLowerCase();
      if (word == 'at' || word == 'to' || word == 'from') {
        if (i + 1 < words.length) {
          return words[i + 1];
        }
      }
    }
    return 'Unknown Merchant';
  }

  static Future<List<Transaction>> categorizeTransactions(
      List<Transaction> transactions) async {
    List<Transaction> categorizedTransactions = [];
    for (final transaction in transactions) {
      try {
        final category = await SMSMLService.categorizeTransaction(
          transaction.merchant,
          transaction.description ?? '',
        );
        categorizedTransactions.add(transaction.copyWith(
          category: category,
          isUncategorized: category == 'Uncategorized',
        ));
      } catch (e) {
        print('Error categorizing transaction: $e');
        categorizedTransactions.add(transaction);
      }
    }
    return categorizedTransactions;
  }
}
