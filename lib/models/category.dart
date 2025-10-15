class Category {
  final String name;
  final String icon;
  final String color;

  const Category({
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<Category> predefinedCategories = [
    Category(name: 'Food & Dining', icon: '🍽️', color: '#FF6B6B'),
    Category(name: 'Transportation', icon: '🚗', color: '#4ECDC4'),
    Category(name: 'Shopping', icon: '🛍️', color: '#45B7D1'),
    Category(name: 'Bills & Utilities', icon: '💡', color: '#96CEB4'),
    Category(name: 'Groceries', icon: '🛒', color: '#FFEAA7'),
    Category(name: 'Entertainment', icon: '🎬', color: '#DDA0DD'),
    Category(name: 'Health & Wellness', icon: '🏥', color: '#98D8C8'),
    Category(name: 'Gifts', icon: '🎁', color: '#F7DC6F'),
    Category(name: 'Investments', icon: '📈', color: '#85C1E9'),
    Category(name: 'Other', icon: '📝', color: '#D5DBDB'),
    Category(name: 'Uncategorized', icon: '❓', color: '#BDC3C7'),
  ];

  static Category getCategoryByName(String name) {
    return predefinedCategories.firstWhere(
      (category) => category.name == name,
      orElse: () => predefinedCategories.last, // Uncategorized
    );
  }
}
