import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class ManualExpenseScreen extends StatefulWidget {
  const ManualExpenseScreen({super.key});

  @override
  State<ManualExpenseScreen> createState() => _ManualExpenseScreenState();
}

class _ManualExpenseScreenState extends State<ManualExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = Category.predefinedCategories.first.name;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAmountField(),
              const SizedBox(height: 16),
              _buildMerchantField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Amount',
        prefixText: '₹ ',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.attach_money),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid amount';
        }
        if (double.parse(value) <= 0) {
          return 'Amount must be greater than 0';
        }
        return null;
      },
    );
  }

  Widget _buildMerchantField() {
    return TextFormField(
      controller: _merchantController,
      decoration: const InputDecoration(
        labelText: 'Merchant/Store Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.store),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter merchant name';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description (Optional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 2,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: Category.predefinedCategories
          .where((category) => category.name != 'Uncategorized')
          .map((category) {
        return DropdownMenuItem<String>(
          value: category.name,
          child: Row(
            children: [
              Text(category.icon),
              const SizedBox(width: 8),
              Text(category.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          DateFormat('dd/MM/yyyy').format(_selectedDate),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        return ElevatedButton(
          onPressed: transactionProvider.isLoading ? null : _submitExpense,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: transactionProvider.isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Add Expense',
                  style: TextStyle(fontSize: 18),
                ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final transaction = Transaction(
      merchant: _merchantController.text.trim(),
      amount: double.parse(_amountController.text),
      category: _selectedCategory,
      date: _selectedDate,
      description: _descriptionController.text.trim(),
      isManual: true,
      isUncategorized: false,
    );

    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    await transactionProvider.addTransaction(transaction);

    if (transactionProvider.error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${transactionProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
