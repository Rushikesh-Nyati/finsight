import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
// ------------------------------------------------------------//
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

  // NEW: Get spending by category for a specific month
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

  // NEW: Get total spending for a specific month
  double getTotalSpendingForMonth(DateTime month) {
    final spending = getMonthlySpendingByCategory(month);
    return spending.values.fold<double>(0.0, (sum, amount) => sum + amount);
  }

  // NEW: Get transactions for a specific month
  List<Transaction> getTransactionsForMonth(DateTime month) {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 1);

    return _transactions
        .where((t) =>
            t.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(endDate))
        .toList();
  }

  // NEW: Get daily spending data for forecasting
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

  // NEW: Get average spending by category over multiple months
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

// ------------------------------------------------------------//
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  BudgetSuggestion? _budgetSuggestion;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBudgetSuggestion();
  }

  Future<void> _loadBudgetSuggestion() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);

      // Get spending data for last 3 months
      final Map<String, List<double>> monthlySpending = {};
      final now = DateTime.now();

      for (int i = 2; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final spending =
            transactionProvider.getMonthlySpendingByCategory(month);

        spending.forEach((category, amount) {
          monthlySpending.putIfAbsent(category, () => []).add(amount);
        });
      }

      final budgetSuggestion =
          await ApiService.getInitialBudget(monthlySpending);
      setState(() {
        _budgetSuggestion = budgetSuggestion;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planning'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBudgetSuggestion,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _budgetSuggestion != null
                  ? _buildBudgetContent()
                  : const Center(child: Text('No budget data available')),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBudgetSuggestion,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetContent() {
    final currentMonth = DateTime.now();
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    final currentSpending =
        transactionProvider.getMonthlySpendingByCategory(currentMonth);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBudgetSummary(currentSpending),
          const SizedBox(height: 24),
          _buildBudgetChart(currentSpending),
          const SizedBox(height: 24),
          _buildBudgetList(currentSpending),
        ],
      ),
    );
  }

  Widget _buildBudgetSummary(Map<String, double> currentSpending) {
    final totalBudget = _budgetSuggestion!.suggestedBudget.values
        .fold(0.0, (sum, amount) => sum + amount);
    final totalSpent =
        currentSpending.values.fold(0.0, (sum, amount) => sum + amount);
    final remaining = totalBudget - totalSpent;
    final percentage = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.green, Colors.greenAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Budget Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Budget',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '₹${totalBudget.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Spent',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '₹${totalSpent.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining: ₹${remaining.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: remaining >= 0 ? Colors.white : Colors.red[200],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.white30,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 100 ? Colors.red[200]! : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetChart(Map<String, double> currentSpending) {
    final budgetData = _budgetSuggestion!.suggestedBudget.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = budgetData.take(5).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget vs Spending',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: budgetData
                          .map((e) => e.value)
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < topCategories.length) {
                            return Text(
                              topCategories[value.toInt()].key.substring(0, 3),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: topCategories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final category = entry.value;
                    final spent = currentSpending[category.key] ?? 0;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: category.value,
                          color: Colors.green[300],
                          width: 16,
                        ),
                        BarChartRodData(
                          toY: spent,
                          color: Colors.blue[300],
                          width: 16,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: Colors.green[300],
                ),
                const SizedBox(width: 8),
                const Text('Budget'),
                const SizedBox(width: 24),
                Container(
                  width: 16,
                  height: 16,
                  color: Colors.blue[300],
                ),
                const SizedBox(width: 8),
                const Text('Spent'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetList(Map<String, double> currentSpending) {
    final budgetData = _budgetSuggestion!.suggestedBudget.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category-wise Budget',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...budgetData.map((entry) {
              final category = entry.key;
              final budget = entry.value;
              final spent = currentSpending[category] ?? 0;
              final percentage = budget > 0 ? (spent / budget) * 100 : 0;
              final remaining = budget - spent;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: percentage > 100 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${spent.toStringAsFixed(0)} / ₹${budget.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          '₹${remaining.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: remaining >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage > 100 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
