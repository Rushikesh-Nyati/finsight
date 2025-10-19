import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class SmsParserService {
  static final _transactionTokens = [
    r'\bdebited\b',
    r'\bcredited\b',
    r'\bpaid\b',
    r'\bsent\b',
    r'\breceived\b',
    r'\btransaction\b',
    r'\btxn\b',
    r'\bUPI\b',
    r'\bNEFT\b',
    r'\bIMPS\b',
    r'\bRTGS\b',
    r'\bwithdrawn\b',
    r'\bwithdrawal\b',
    r'\bspent\b',
    r'\bpaid to\b',
    r'\bPOS\b',
    r'\bATM\b',
    r'\bpurchase\b',
  ];

  // ✅ EXPANDED: More aggressive promo detection
  static final _promoTokens = [
    r'\bunsubscribe\b',
    r'\boffer\b',
    r'\bdiscount\b',
    r'\bsale\b',
    r'\bclick here\b',
    r'\bvisit\b',
    r'\bshop now\b',
    r'\bpromo\b',
    r'\bsubscribe\b',
    r'\bfree\b',
    r'\bwin\b',
    r'\bwon\b',
    r'\blimited offer\b',
    r'\bexclusive\b',
    r'\bcashback offer\b',
    r'\bdata pack\b',
    r'\brecharge now\b',
    r'\bupgrade\b',
    r'\bclaim\b',
    r'\breward\b',
    r'\bbonus\b',
    r'\bgift\b',
    r'\bcontest\b',
    r'\bjackpot\b',
    r'\bscratch\b',
    r'\bspin\b',
    r'\bupto\b',
    r'\bup to\b',
    r'\bget rs\b',
    r'\bearn rs\b',
    r'\bsave rs\b',
    r'\bwin rs\b',
    r'\blast chance\b',
    r'\bexpiring\b',
    r'\bhurry\b',
    r'\blimited time\b',
    r'\bdon\t miss\b',
    r'\btoday only\b',
    r'\bspecial price\b',
    r'\bcoupon\b',
    r'\bvoucher\b',
    r'\bdownload app\b',
    r'\binstall\b',
    r'\bregister now\b',
    r'\bsign up\b',
    r'\bjoin now\b',
    r'\bactivate\b',
    r'\bapply now\b',
  ];

  static final _trustedSenders = [
    'HDFCBK',
    'HDFC',
    'ICICIB',
    'ICICI',
    'SBIIN',
    'SBI',
    'AXISBANK',
    'AXIS',
    'KOTAKBK',
    'KOTAK',
    'YESBNK',
    'YES',
    'SBIUPI',
    'PAYTM',
    'GPAY',
    'PHONEPE',
    'AMAZNP',
    'BHARTP',
    'MOBIKW',
    'FREECHARGE',
    'OLAMNY',
    'IMOBILE',
  ];

  // ✅ ADD THIS NEW SECTION
  static final _exclusionPatterns = [
    r'\bcould not process\b',
    r'\bunable to process\b',
    r'\bfailed\b',
    r'\bfailure\b',
    r'\bnil balance\b',
    r'\binsufficient\b',
    r'\blimit is.*increased\b',
    r'\blimit increased\b',
    r'\blimit enhanced\b',
    r'\bnew limit\b',
    r'\beligible to claim\b',
    r'\beligible for\b',
    r'\bdata loan\b',
    r'\bget.*loan\b',
    r'\bavail.*loan\b',
    r'\breminder\b',
    r'\balert.*could not\b',
    r'\bannual reminder\b',
    r'\bterms.*conditions\b',
    r'\bprivacy policy\b',
    r'\buser agreement\b',
    r'\bcompliance\b',
    r'\bsubscriptions\b',
    r'\bwatch now\b',
    r'\bcontact.*distributor\b',
    r'\bcall us on\b',
    r'\bemail us\b',
    r'\bvisit.*branch\b',
    r'\bsettlement\b',
    r'\bquarterly settlement\b',
    r'\bpayout settlement\b',
    r'\bconsider recharging\b',
    r'\bignore if done\b',
    r'\bignore if\b',
    r'\bcheck balance\b',
    r'\brecharge.*a/c\b',
    r'\brecharge.*account\b',
    r'\bct3\.io\b',
    r'\bpending.*settlement\b',
    r'\bdue.*settlement\b',
  ];

  static late final RegExp _transactionTokenRegex;
  static late final RegExp _promoTokenRegex;
  static late final RegExp _exclusionRegex;
  static bool _initialized = false;

  static void _initialize() {
    if (_initialized) return;

    _transactionTokenRegex = RegExp(
      _transactionTokens.join('|'),
      caseSensitive: false,
    );

    _promoTokenRegex = RegExp(
      _promoTokens.join('|'),
      caseSensitive: false,
    );
    _exclusionRegex = RegExp(
      _exclusionPatterns.join('|'),
      caseSensitive: false,
    );

    _initialized = true;
  }

  // ✅ ENHANCED: More sophisticated promotional detection
  static bool _looksPromotional(String text) {
    final lowerText = text.toLowerCase();

    // Definitely not promo
    if (lowerText.contains('not you')) {
      return false;
    }

    // Strong promo indicators (multiple matches = definitely promo)
    int promoScore = 0;

    if (_promoTokenRegex.hasMatch(text)) promoScore += 2;

    // Check for multiple promotional phrases
    if (lowerText
        .contains(RegExp(r'get\s+rs|earn\s+rs|win\s+rs|save\s+rs|upto\s+rs')))
      promoScore += 2;
    if (lowerText.contains(RegExp(r'click|visit|shop now|buy now|order now')))
      promoScore += 1;
    if (lowerText.contains(RegExp(r'%\s*off|percent off|discount')))
      promoScore += 2;
    if (lowerText.contains(RegExp(r'https?:\/\/|www\.'))) promoScore += 1;
    if (lowerText.contains(RegExp(r'download|install|register|sign up')))
      promoScore += 1;
    if (lowerText.contains(RegExp(r'cashback|reward|bonus|gift|prize')))
      promoScore += 1;
    if (lowerText
        .contains(RegExp(r'limited|hurry|expire|last chance|today only')))
      promoScore += 1;
    if (lowerText.contains(RegExp(r'congratulations|congrats|winner')))
      promoScore += 2;

    // If it has a URL but no strong transaction indicators
    if (text.contains(RegExp(r'https?:\/\/|www\.')) &&
        !_transactionTokenRegex.hasMatch(text)) {
      promoScore += 2;
    }

    // Promo if score is 3 or higher
    return promoScore >= 3;
  }

  static double _scoreMessage(String text, String sender) {
    var score = 0.0;

    // ✅ CRITICAL: Check exclusions FIRST - instant rejection
    if (_exclusionRegex.hasMatch(text)) {
      if (kDebugMode) {
        debugPrint('🚫 Matched exclusion pattern - NOT a real transaction');
      }
      return -100.0; // Instant rejection
    }

    // Check promo second
    if (_looksPromotional(text)) {
      if (kDebugMode) {
        debugPrint('🚫 Detected promotional content');
      }
      return -10.0; // Instant rejection
    }

    // Transaction indicators
    if (_transactionTokenRegex.hasMatch(text)) score += 3.0;

    final lower = text.toLowerCase();

    // Amount patterns
    if (lower.contains(RegExp(r'rs\.?\s*\d|₹\s*\d|inr\s*\d'))) score += 2.0;

    // Strong transaction phrases
    if (lower.contains('sent rs')) score += 2.5;
    if (lower.contains('received rs')) score += 2.5;
    if (lower.contains('credited')) score += 2.0;
    if (lower.contains('debited')) score += 2.0;
    if (lower.contains('paid to')) score += 2.0;
    if (lower.contains('transferred')) score += 2.0;

    // Payment methods
    if (lower.contains('upi')) score += 1.5;
    if (lower.contains('neft')) score += 1.5;
    if (lower.contains('imps')) score += 1.5;
    if (lower.contains('rtgs')) score += 1.5;

    // Account references
    if (lower.contains('ref')) score += 0.5;
    if (lower.contains(RegExp(r'a\/c\s*\*?\d{4}'))) score += 1.5;
    if (lower.contains('from') && lower.contains('a/c')) score += 1.0;
    if (lower.contains('to') && lower.contains('a/c')) score += 1.0;

    // Balance mentions (weaker indicator)
    if (lower.contains('balance')) score += 0.3;

    // Trusted sender bonus
    final senderUpper = sender.toUpperCase();
    if (_trustedSenders.any((s) => senderUpper.contains(s))) {
      score += 2.5;
    }

    return score;
  }

///////////////
  static bool isTransactionSMS(String senderAddress, String messageBody) {
    _initialize();

    final score = _scoreMessage(messageBody, senderAddress);
    const threshold = 4.0; // ✅ Slightly higher threshold for better accuracy

    if (kDebugMode) {
      debugPrint('\n📨 SMS from: $senderAddress');
      debugPrint(
          '📝 Text: ${messageBody.substring(0, messageBody.length > 80 ? 80 : messageBody.length)}...');
      debugPrint('⭐ Score: $score (threshold: $threshold)');
      debugPrint(score >= threshold ? '✅ ACCEPTED\n' : '❌ REJECTED\n');
    }

    return score >= threshold;
  }

  static double? _parseAmount(String text) {
    // Priority 1: Standard formats (Rs., INR, ₹ followed by amount)
    final standardPattern = RegExp(
      r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );
    var match = standardPattern.firstMatch(text);

    if (match != null) {
      String amountStr = match.group(1) ?? '';
      amountStr = amountStr.replaceAll(',', '');

      try {
        final amount = double.parse(amountStr);
        if (amount > 0) {
          if (kDebugMode) {
            debugPrint('💵 Amount extracted: ₹$amount');
          }
          return amount;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Could not parse amount: $amountStr');
        }
      }
    }

    // Priority 2: Look for standalone numbers (last resort)
    final numberPattern = RegExp(r'\b(\d{1,10}(?:\.\d{1,2})?)\b');
    final matches = numberPattern.allMatches(text);

    for (final match in matches) {
      try {
        final amount = double.parse(match.group(1) ?? '0');
        if (amount >= 0.01 && amount <= 1000000) {
          if (kDebugMode) {
            debugPrint('💵 Amount extracted (fallback): ₹$amount');
          }
          return amount;
        }
      } catch (e) {
        continue;
      }
    }

    if (kDebugMode) {
      debugPrint('❌ Could not extract amount');
    }
    return null;
  }

///////////////
  static DateTime? _parseDate(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('today')) {
      return DateTime.now();
    }
    if (lower.contains('yesterday')) {
      return DateTime.now().subtract(const Duration(days: 1));
    }

    final datePatterns = [
      RegExp(r'on\s+(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})', caseSensitive: false),
      RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b'),
      RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2})\b'),
      RegExp(
          r'\b(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[,\s]+(\d{2,4})',
          caseSensitive: false),
      RegExp(
          r'\b(\d{1,2})-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-(\d{2,4})',
          caseSensitive: false),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          if (match.groupCount >= 3) {
            int day = int.parse(match.group(1)!);
            dynamic monthValue = match.group(2)!;
            String yearStr = match.group(3)!;

            int month;
            int year;

            if (int.tryParse(monthValue) != null) {
              month = int.parse(monthValue);
              year = int.parse(yearStr);

              if (year < 100) {
                year += (year > 50) ? 1900 : 2000;
              }
            } else {
              final monthNames = {
                'jan': 1,
                'feb': 2,
                'mar': 3,
                'apr': 4,
                'may': 5,
                'jun': 6,
                'jul': 7,
                'aug': 8,
                'sep': 9,
                'oct': 10,
                'nov': 11,
                'dec': 12,
              };
              month = monthNames[
                      monthValue.toString().toLowerCase().substring(0, 3)] ??
                  1;
              year = int.parse(yearStr);

              if (year < 100) {
                year += (year > 50) ? 1900 : 2000;
              }
            }

            if (month < 1 || month > 12 || day < 1 || day > 31) {
              continue;
            }

            try {
              final parsedDate = DateTime(year, month, day);

              if (kDebugMode) {
                debugPrint(
                    '📅 Parsed date: ${DateFormat('dd/MM/yyyy').format(parsedDate)} from: "${match.group(0)}"');
              }

              return parsedDate;
            } catch (e) {
              if (kDebugMode) {
                debugPrint('⚠️ Invalid date: Y=$year M=$month D=$day');
              }
              continue;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Date parsing error: $e');
          }
          continue;
        }
      }
    }

    if (kDebugMode) {
      debugPrint('⚠️ No date found in SMS text, will use SMS timestamp');
    }

    return null;
  }

  static String? _extractMerchant(String text) {
    final toPattern = RegExp(
      r'to\s+([A-Z][A-Za-z0-9\s&\.\-]{2,50})(?:\s+on|\s+ref|\n|$)',
      caseSensitive: false,
      multiLine: true,
    );
    var match = toPattern.firstMatch(text);
    if (match != null) {
      String merchant = match.group(1)!.trim();
      merchant = merchant
          .split(RegExp(r'\s+on\s+|\s+ref\s+', caseSensitive: false))[0]
          .trim();
      if (merchant.length > 2) return merchant;
    }

    final patterns = [
      RegExp(r'\b(?:at|via|from)\s+([A-Z][A-Za-z0-9&\.\- ]{2,30})',
          caseSensitive: false),
      RegExp(r'\b([A-Z][A-Z\s]{2,30})(?:\s+on|\.|,)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      match = pattern.firstMatch(text);
      if (match != null) {
        String merchant = match.group(1)!.trim();
        merchant = merchant.split(RegExp(r'[\.\,\;]|on |for '))[0].trim();
        if (merchant.length > 2) return merchant;
      }
    }

    return null;
  }

  static Map<String, dynamic>? parseTransaction(
      String senderAddress, String messageBody) {
    if (!isTransactionSMS(senderAddress, messageBody)) {
      return null;
    }

    final lower = messageBody.toLowerCase();

    // ✅ IMPROVED: Better transaction type detection with context awareness
    String type = 'debit'; // Default

    // Strong CREDIT indicators (money coming IN)
    if (lower.contains('credited') ||
        lower.contains('received') ||
        lower.contains('deposited') ||
        lower.contains('refund') ||
        lower.contains('credit alert')) {
      type = 'credit';
    }
    // Context-aware: "transferred TO your account" = CREDIT
    else if (lower
        .contains(RegExp(r'transferred\s+to\s+your\s+(bank\s+)?a(/|c)'))) {
      type = 'credit';
    }
    // Context-aware: "transferred TO your Bank A/C" = CREDIT
    else if (lower.contains(RegExp(r'to\s+your\s+bank\s+a(/|c)'))) {
      type = 'credit';
    }
    // Strong DEBIT indicators (money going OUT)
    else if (lower.contains('sent') ||
        lower.contains('paid') ||
        lower.contains('debited') ||
        lower.contains('withdrawn') ||
        lower.contains('sent rs')) {
      type = 'debit';
    }
    // Context-aware: "transferred FROM your account" = DEBIT
    else if (lower
        .contains(RegExp(r'from\s+(hdfc\s+bank\s+)?a(/|c)\s*\*?\d'))) {
      type = 'debit';
    }

    final amount = _parseAmount(messageBody);
    final date = _parseDate(messageBody);
    final merchant = _extractMerchant(messageBody);

    if (amount == null || amount <= 0) {
      if (kDebugMode) {
        debugPrint('⚠️ Skipping transaction - invalid amount');
      }
      return null;
    }

    if (kDebugMode) {
      debugPrint('💰 Parsed: $type ₹$amount');
      debugPrint(
          '📅 Date: ${date != null ? DateFormat('dd/MM/yyyy').format(date) : "Not found (will use SMS timestamp)"}');
      debugPrint('🏪 Merchant: ${merchant ?? "Unknown"}');
    }

    return {
      'type': type,
      'amount': amount,
      'merchant': merchant ?? 'Unknown',
      'date': date ?? DateTime.now(),
      'sender': senderAddress,
    };
  }

  static String categorizeTransaction(String merchant, String message) {
    final lower = '${merchant.toLowerCase()} ${message.toLowerCase()}';

    final personNamePattern = RegExp(
      r'\b(mr|mrs|ms|shri|smt|kumar|bhai|balu|ganesh|karan|mangesh|chavan|dalavi|londhe|firoz|ansari|ahir)\b',
      caseSensitive: false,
    );

    if (personNamePattern.hasMatch(merchant.toLowerCase())) {
      return 'Personal Transfer';
    }

    if (lower.contains(RegExp(
        r'swiggy|zomato|food|restaurant|cafe|pizza|burger|domino|mcdonalds|kfc|mc donalds'))) {
      return 'Food & Dining';
    } else if (lower
        .contains(RegExp(r'amazon|flipkart|myntra|shopping|mall|store'))) {
      return 'Shopping';
    } else if (lower.contains(RegExp(
        r'uber|ola|rapido|petrol|fuel|metro|railway|irctc|petrol.*depot'))) {
      return 'Transportation';
    } else if (lower
        .contains(RegExp(r'electricity|water|gas|bill|recharge|broadband'))) {
      return 'Bills & Utilities';
    } else if (lower
        .contains(RegExp(r'netflix|prime|hotstar|spotify|movie|cinema'))) {
      return 'Entertainment';
    } else if (lower
        .contains(RegExp(r'pharmacy|medicine|hospital|doctor|apollo|1mg'))) {
      return 'Healthcare';
    } else if (lower.contains(
        RegExp(r'school|college|course|tuition|education|institute'))) {
      return 'Education';
    } else if (lower.contains(
        RegExp(r'mutual fund|sip|stock|zerodha|groww|investment|angel one'))) {
      return 'Investments';
    } else if (lower.contains(
        RegExp(r'grocery|supermarket|mart|vegetables|mobikwik|mataji'))) {
      return 'Groceries';
    }

    return 'Uncategorized';
  }
}
