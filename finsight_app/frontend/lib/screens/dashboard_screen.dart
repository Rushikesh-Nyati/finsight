import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import 'manual_expense_screen.dart';
import 'budget_screen.dart' as budget;
import 'forecast_screen.dart';
import 'savings_planner_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false)
          .loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FinSight'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<TransactionProvider>(context, listen: false)
                  .loadTransactions();
            },
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          if (transactionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter transactions for current month only
          final now = DateTime.now();
          final currentMonthStart = DateTime(now.year, now.month, 1);
          final nextMonthStart = DateTime(now.year, now.month + 1, 1);

          final currentMonthTransactions = transactionProvider.transactions
              .where((t) =>
                  t.date.isAfter(
                      currentMonthStart.subtract(const Duration(seconds: 1))) &&
                  t.date.isBefore(nextMonthStart))
              .toList();

          final totalSpending =
              _calculateTotalSpending(currentMonthTransactions);
          final spendingByCategory =
              _calculateSpendingByCategory(currentMonthTransactions);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSpendingSummaryCard(totalSpending),
                const SizedBox(height: 24),
                _buildSpendingChart(spendingByCategory),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                // CHANGED: Show ALL transactions, not just 5
                _buildRecentTransactions(currentMonthTransactions),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ManualExpenseScreen()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  double _calculateTotalSpending(List<Transaction> transactions) {
    return transactions.fold<double>(
        0.0, (sum, transaction) => sum + transaction.amount);
  }

  Map<String, double> _calculateSpendingByCategory(
      List<Transaction> transactions) {
    final Map<String, double> categorySpending = {};
    for (final transaction in transactions) {
      categorySpending[transaction.category] =
          (categorySpending[transaction.category] ?? 0) + transaction.amount;
    }
    return categorySpending;
  }

  Widget _buildSpendingSummaryCard(double totalSpending) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Spends this Month',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${totalSpending.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingChart(Map<String, double> spendingByCategory) {
    if (spendingByCategory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No spending data available for this month'),
        ),
      );
    }

    final sortedCategories = spendingByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(5).toList();
    final maxSpending = topCategories.isEmpty ? 1.0 : topCategories.first.value;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxSpending * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${topCategories[group.x.toInt()].key}\n₹${topCategories[group.x.toInt()].value.toStringAsFixed(0)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= topCategories.length) {
                            return const Text('');
                          }
                          final category = topCategories[value.toInt()].key;
                          final cat = Category.getCategoryByName(category);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              cat.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                          );
                        },
                        reservedSize: 40,
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
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxSpending / 5,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: topCategories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final categoryData = entry.value;
                    final color = _getCategoryColor(categoryData.key);

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: categoryData.value,
                          color: color,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: topCategories.map((entry) {
                final color = _getCategoryColor(entry.key);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Budget',
                Icons.account_balance_wallet,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const budget.BudgetScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Forecast',
                Icons.trending_up,
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ForecastScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Savings Plan',
                Icons.savings,
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SavingsPlannerScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Add Expense',
                Icons.add,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ManualExpenseScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UPDATED: Show ALL transactions with header showing count
  Widget _buildRecentTransactions(List<Transaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'All Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${transactions.length} this month',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No transactions found for this month'),
            ),
          )
        else
          ...transactions
              .map((transaction) => _buildTransactionTile(transaction)),
      ],
    );
  }

  // UPDATED: Made clickable with onTap to open edit dialog
  Widget _buildTransactionTile(Transaction transaction) {
    final category = Category.getCategoryByName(transaction.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () =>
            _showEditTransactionDialog(transaction), // ADDED: Click to edit
        leading: CircleAvatar(
          backgroundColor:
              Color(int.parse(category.color.replaceAll('#', '0xFF'))),
          child: Text(
            category.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(transaction.merchant),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${transaction.category} • ${_formatDate(transaction.date)}'),
            if (transaction.description != null &&
                transaction.description!.isNotEmpty)
              Text(
                transaction.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${transaction.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: transaction.amount > 0 ? Colors.red : Colors.green,
              ),
            ),
            if (transaction.isUncategorized)
              const Icon(
                Icons.warning,
                color: Colors.orange,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  // NEW: Dialog to edit transaction
  void _showEditTransactionDialog(Transaction transaction) {
    String selectedCategory = transaction.category;
    TextEditingController noteController =
        TextEditingController(text: transaction.description ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit ${transaction.merchant}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount (read-only)
                    Text(
                      'Amount: ₹${transaction.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date: ${_formatDate(transaction.date)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const Divider(height: 24),

                    // Category selector
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Category.predefinedCategories
                          .where((c) => c.name != 'Uncategorized')
                          .map((category) {
                        final isSelected = category.name == selectedCategory;
                        return FilterChip(
                          avatar: Text(category.icon),
                          label: Text(category.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedCategory = category.name;
                            });
                          },
                          selectedColor: Color(int.parse(
                              category.color.replaceAll('#', '0xFF'))),
                          backgroundColor: Colors.grey[200],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Note field
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        hintText: 'Add a note about this transaction',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update transaction
                    final updatedTransaction = transaction.copyWith(
                      category: selectedCategory,
                      description: noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim(),
                      isUncategorized: false,
                    );

                    Provider.of<TransactionProvider>(context, listen: false)
                        .updateTransaction(updatedTransaction);

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction updated!')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getCategoryColor(String categoryName) {
    final category = Category.getCategoryByName(categoryName);
    return Color(int.parse(category.color.replaceAll('#', '0xFF')));
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
