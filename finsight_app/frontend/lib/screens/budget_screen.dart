import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
import '../providers/transaction_provider.dart';

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
            _getMonthlySpendingByCategory(transactionProvider, month);

        spending.forEach((category, amount) {
          monthlySpending.putIfAbsent(category, () => []).add(amount);
        });
      }

      final budgetSuggestion =
          await ApiService.getInitialBudget(monthlySpending);

      if (mounted) {
        setState(() {
          _budgetSuggestion = budgetSuggestion;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading budget suggestion: $e');
      }
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, double> _getMonthlySpendingByCategory(
      TransactionProvider provider, DateTime month) {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);

    final transactions =
        provider.getTransactionsByDateRange(startDate, endDate);
    final Map<String, double> categorySpending = {};

    for (final transaction in transactions) {
      if (transaction.type == 'debit') {
        categorySpending[transaction.category] =
            (categorySpending[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return categorySpending;
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
        _getMonthlySpendingByCategory(transactionProvider, currentMonth);

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
