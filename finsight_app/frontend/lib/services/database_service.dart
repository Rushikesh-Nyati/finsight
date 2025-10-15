import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as models;

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'transactions';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'finsight.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        merchant TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        isManual INTEGER NOT NULL DEFAULT 0,
        isUncategorized INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // NEW: Check if transaction already exists (to prevent duplicates)
  static Future<bool> transactionExists(
    String merchant,
    double amount,
    DateTime date,
  ) async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: 'merchant = ? AND amount = ? AND date = ?',
      whereArgs: [merchant, amount, date.toIso8601String()],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // UPDATED: Check for duplicates before inserting
  static Future<int> insertTransaction(models.Transaction transaction) async {
    final db = await database;

    // Check if transaction already exists
    final exists = await transactionExists(
      transaction.merchant,
      transaction.amount,
      transaction.date,
    );

    if (exists) {
      print(
          '⚠️ Duplicate transaction detected, skipping: ${transaction.merchant}');
      return -1; // Return -1 to indicate duplicate
    }

    return await db.insert(_tableName, transaction.toMap());
  }

  // BULK INSERT with duplicate checking
  static Future<int> insertTransactionsBatch(
      List<models.Transaction> transactions) async {
    final db = await database;
    int insertedCount = 0;

    for (final transaction in transactions) {
      final exists = await transactionExists(
        transaction.merchant,
        transaction.amount,
        transaction.date,
      );

      if (!exists) {
        await db.insert(_tableName, transaction.toMap());
        insertedCount++;
      }
    }

    print(
        '✅ Inserted $insertedCount new transactions (${transactions.length - insertedCount} duplicates skipped)');
    return insertedCount;
  }

  static Future<List<models.Transaction>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'date DESC',
    );
    return List.generate(
        maps.length, (i) => models.Transaction.fromMap(maps[i]));
  }

  static Future<List<models.Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );
    return List.generate(
        maps.length, (i) => models.Transaction.fromMap(maps[i]));
  }

  static Future<List<models.Transaction>> getTransactionsByCategory(
      String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
    return List.generate(
        maps.length, (i) => models.Transaction.fromMap(maps[i]));
  }

  static Future<List<models.Transaction>> getUncategorizedTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'isUncategorized = ?',
      whereArgs: [1],
      orderBy: 'date DESC',
    );
    return List.generate(
        maps.length, (i) => models.Transaction.fromMap(maps[i]));
  }

  static Future<int> updateTransaction(models.Transaction transaction) async {
    final db = await database;
    return await db.update(
      _tableName,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  static Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<Map<String, double>> getMonthlySpendingByCategory(
      DateTime month) async {
    final db = await database;
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );

    Map<String, double> spendingByCategory = {};
    for (var map in maps) {
      final category = map['category'] as String;
      final amount = map['amount'] as double;
      spendingByCategory[category] =
          (spendingByCategory[category] ?? 0) + amount;
    }

    return spendingByCategory;
  }

  static Future<double> getTotalSpendingForMonth(DateTime month) async {
    final spendingByCategory = await getMonthlySpendingByCategory(month);
    return spendingByCategory.values
        .fold<double>(0.0, (sum, amount) => sum + amount);
  }

  static Future<List<Map<String, dynamic>>> getDailySpendingData(
      int days) async {
    final db = await database;
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DATE(date) as date, SUM(amount) as amount
      FROM $_tableName
      WHERE date BETWEEN ? AND ?
      GROUP BY DATE(date)
      ORDER BY date ASC
    ''', [
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ]);

    return maps;
  }

  static Future<Map<String, double>> getAverageSpendingByCategory(
      int months) async {
    final db = await database;
    final endDate = DateTime.now();
    final startDate = DateTime(endDate.year, endDate.month - months, 1);
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );

    Map<String, List<double>> categoryAmounts = {};
    for (var map in maps) {
      final category = map['category'] as String;
      final amount = map['amount'] as double;
      categoryAmounts.putIfAbsent(category, () => []).add(amount);
    }

    Map<String, double> averageSpending = {};
    categoryAmounts.forEach((category, amounts) {
      averageSpending[category] =
          amounts.reduce((a, b) => a + b) / amounts.length;
    });

    return averageSpending;
  }

  // NEW: Get latest transaction date (for incremental sync)
  static Future<DateTime?> getLatestTransactionDate() async {
    final db = await database;
    final result = await db.query(
      _tableName,
      orderBy: 'date DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return DateTime.parse(result.first['date'] as String);
  }
}
