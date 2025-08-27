import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/enums.dart';
import '../models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  final List<Account> accounts;
  final List<Category> categories;

  const AddTransactionScreen({
    Key? key,
    required this.accounts,
    required this.categories,
  }) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  // FORM CONTROLLERS
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  // FOCUS NODES FOR KEYBOARD NAVIGATION
  final _titleFocusNode = FocusNode();
  final _amountFocusNode = FocusNode();
  final _notesFocusNode = FocusNode();

  // FORM VARIABLES
  TransactionType _selectedType = TransactionType.expense;
  Account? _selectedAccount;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.accounts.isNotEmpty) {
      _selectedAccount = widget.accounts.first;
    }
    if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.firstWhere(
        (cat) => cat.type == CategoryType.expense,
        orElse: () => widget.categories.first,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _titleFocusNode.dispose();
    _amountFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an account first')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final transaction = Transaction(
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        date: _selectedDate,
        type: _selectedType,
        accountId: _selectedAccount!.id!,
        categoryId: _selectedCategory!.id!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await _dbHelper.insertTransaction(transaction);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction added successfully!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving transaction: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  List<Category> get _filteredCategories {
    final targetType = _selectedType == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;

    return widget.categories.where((cat) => cat.type == targetType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveTransaction,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TRANSACTION TYPE TOGGLE - NEW DESIGN
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = TransactionType.income;
                            _selectedCategory = _filteredCategories.isNotEmpty
                                ? _filteredCategories.first
                                : null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: _selectedType == TransactionType.income
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF2E7D32),
                                      Color(0xFF4CAF50),
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.trending_up,
                                color: _selectedType == TransactionType.income
                                    ? Colors.white
                                    : const Color(0xFF2E7D32),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Income',
                                style: TextStyle(
                                  color: _selectedType == TransactionType.income
                                      ? Colors.white
                                      : const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = TransactionType.expense;
                            _selectedCategory = _filteredCategories.isNotEmpty
                                ? _filteredCategories.first
                                : null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: _selectedType == TransactionType.expense
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFD32F2F),
                                      Color(0xFFE57373),
                                    ],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.trending_down,
                                color: _selectedType == TransactionType.expense
                                    ? Colors.white
                                    : const Color(0xFFD32F2F),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Expense',
                                style: TextStyle(
                                  color:
                                      _selectedType == TransactionType.expense
                                      ? Colors.white
                                      : const Color(0xFFD32F2F),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // TITLE FIELD - WITH KEYBOARD NAVIGATION
              TextFormField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                textInputAction:
                    TextInputAction.next, // FIXED: Keyboard navigation
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_amountFocusNode),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Lunch, Salary, Groceries',
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter transaction title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // AMOUNT FIELD - WITH KEYBOARD NAVIGATION
              TextFormField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                textInputAction:
                    TextInputAction.next, // FIXED: Keyboard navigation
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_notesFocusNode),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value.trim()) <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ACCOUNT DROPDOWN
              if (widget.accounts.isNotEmpty) ...[
                DropdownButtonFormField<Account>(
                  value: _selectedAccount,
                  decoration: const InputDecoration(
                    labelText: 'Account',
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                  items: widget.accounts.map((account) {
                    return DropdownMenuItem(
                      value: account,
                      child: Text(account.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedAccount = value);
                  },
                ),
                const SizedBox(height: 20),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No accounts found. Please add an account first.',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // CATEGORY DROPDOWN
              if (_filteredCategories.isNotEmpty) ...[
                DropdownButtonFormField<Category>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _filteredCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Text(
                            category.icon,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                ),
                const SizedBox(height: 20),
              ],

              // DATE SELECTOR
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF1A237E),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // NOTES FIELD - WITH KEYBOARD NAVIGATION
              TextFormField(
                controller: _notesController,
                focusNode: _notesFocusNode,
                textInputAction: TextInputAction.done, // FIXED: Last field
                onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add any additional details...',
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 36),

              // SAVE BUTTON - NEW DESIGN
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedType == TransactionType.income
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedType == TransactionType.income
                                  ? Icons.add_circle_outline
                                  : Icons.remove_circle_outline,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Add ${_selectedType == TransactionType.income ? 'Income' : 'Expense'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
