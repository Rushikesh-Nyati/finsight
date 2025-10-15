import '../models/transaction.dart';
import '../models/category.dart';

class SMSMLService {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Using advanced rule-based categorization
    print('Initializing rule-based transaction categorization...');
    _isInitialized = true;
    print('Rule-based categorization ready!');
  }

  static Future<String> categorizeTransaction(
      String merchant, String description) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Enhanced rule-based categorization logic
    final lowerMerchant = merchant.toLowerCase();
    final lowerDesc = description.toLowerCase();
    final combined = '$lowerMerchant $lowerDesc';

    // Food & Dining
    if (_containsAny(combined, [
      'restaurant',
      'cafe',
      'coffee',
      'food',
      'pizza',
      'burger',
      'mcdonald',
      'kfc',
      'dominos',
      'zomato',
      'swiggy',
      'starbucks',
      'hotel',
      'dining',
      'eatery',
      'bistro',
      'bakery',
      'subway',
      'dunkin',
      'baskin',
      'haagen',
      'chinese',
      'indian',
      'cuisine',
      'meal',
      'breakfast',
      'lunch',
      'dinner',
      'eat'
    ])) {
      return 'Food & Dining';
    }

    // Transportation
    if (_containsAny(combined, [
      'uber',
      'ola',
      'rapido',
      'petrol',
      'fuel',
      'gas',
      'taxi',
      'auto',
      'metro',
      'bus',
      'parking',
      'toll',
      'transport',
      'railway',
      'train',
      'flight',
      'airline',
      'indigo',
      'spicejet',
      'car',
      'bike',
      'scooter',
      'vehicle',
      'travel',
      'cab'
    ])) {
      return 'Transportation';
    }

    // Shopping
    if (_containsAny(combined, [
      'amazon',
      'flipkart',
      'myntra',
      'ajio',
      'shop',
      'store',
      'mall',
      'retail',
      'purchase',
      'buy',
      'shopping',
      'market',
      'meesho',
      'nykaa',
      'lifestyle',
      'max',
      'westside',
      'reliance',
      'clothing',
      'fashion',
      'shoes',
      'accessories',
      'electronics'
    ])) {
      return 'Shopping';
    }

    // Bills & Utilities
    if (_containsAny(combined, [
      'electricity',
      'water',
      'gas',
      'bill',
      'utility',
      'recharge',
      'mobile',
      'internet',
      'broadband',
      'wifi',
      'jio',
      'airtel',
      'vodafone',
      'bsnl',
      'tata',
      'paytm',
      'phonepe',
      'payment',
      'dth',
      'cable',
      'subscription',
      'rent',
      'maintenance'
    ])) {
      return 'Bills & Utilities';
    }

    // Groceries
    if (_containsAny(combined, [
      'grocery',
      'supermarket',
      'bigbasket',
      'grofers',
      'blinkit',
      'dunzo',
      'mart',
      'provisions',
      'dmart',
      'reliance fresh',
      'more',
      'spencer',
      'vegetables',
      'fruits',
      'dairy',
      'milk',
      'bread',
      'eggs',
      'rice',
      'flour',
      'oil'
    ])) {
      return 'Groceries';
    }

    // Entertainment
    if (_containsAny(combined, [
      'movie',
      'cinema',
      'netflix',
      'prime',
      'hotstar',
      'spotify',
      'youtube',
      'game',
      'entertainment',
      'pvr',
      'inox',
      'theatre',
      'concert',
      'event',
      'ticket',
      'show',
      'disney',
      'zee5',
      'sonyliv',
      'voot',
      'music',
      'streaming'
    ])) {
      return 'Entertainment';
    }

    // Health & Wellness
    if (_containsAny(combined, [
      'hospital',
      'clinic',
      'doctor',
      'pharmacy',
      'medicine',
      'health',
      'gym',
      'fitness',
      'apollo',
      'medplus',
      'medical',
      'healthcare',
      'diagnostic',
      'lab',
      'test',
      'consultation',
      'treatment',
      'therapy',
      'wellness',
      'yoga',
      'physiotherapy',
      'dental',
      'netmeds',
      'pharmeasy',
      '1mg',
      'vitamin',
      'supplement'
    ])) {
      return 'Health & Wellness';
    }

    // Gifts
    if (_containsAny(combined, [
      'gift',
      'flowers',
      'bouquet',
      'ferns n petals',
      'present',
      'birthday',
      'anniversary',
      'celebration',
      'greeting',
      'card',
      'donation'
    ])) {
      return 'Gifts';
    }

    // Investments
    if (_containsAny(combined, [
      'mutual',
      'sip',
      'fund',
      'stock',
      'zerodha',
      'groww',
      'upstox',
      'investment',
      'nps',
      'equity',
      'share',
      'trading',
      'demat',
      'ipo',
      'bond',
      'gold',
      'insurance',
      'policy',
      'lic',
      'fd'
    ])) {
      return 'Investments';
    }

    // Check for specific transaction types in description
    if (_containsAny(lowerDesc, ['atm', 'withdrawal', 'cash'])) {
      return 'Other';
    }

    if (_containsAny(lowerDesc, ['transfer', 'sent', 'upi'])) {
      return 'Other';
    }

    // Default to Uncategorized
    return 'Uncategorized';
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  // Helper method to get category confidence (for future ML integration)
  static double getCategoryConfidence(String category) {
    // Rule-based always returns moderate confidence
    return category == 'Uncategorized' ? 0.3 : 0.7;
  }

  // Method to improve categorization based on user feedback
  static final Map<String, List<String>> _userKeywords = {};

  static void addUserKeyword(String category, String keyword) {
    _userKeywords.putIfAbsent(category, () => []).add(keyword.toLowerCase());
  }

  static Future<String> categorizeWithUserPreferences(
      String merchant, String description) async {
    final combined = '$merchant $description'.toLowerCase();

    // Check user-defined keywords first
    for (var entry in _userKeywords.entries) {
      if (_containsAny(combined, entry.value)) {
        return entry.key;
      }
    }

    // Fall back to default categorization
    return categorizeTransaction(merchant, description);
  }

  // Dispose method (kept for compatibility)
  static void dispose() {
    _isInitialized = false;
    _userKeywords.clear();
  }
}
