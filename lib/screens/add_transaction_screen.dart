import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/enums.dart';
import '../models/transaction.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final List<Account> accounts;
  final List<Category> categories;
  final Transaction? transaction; // NEW: For editing existing transactions

  const AddTransactionScreen({
    super.key,
    required this.accounts,
    required this.categories,
    this.transaction, // NEW: Transaction to edit
  });

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
  // FOCUS NODES FOR SEAMLESS KEYBOARD NAVIGATION
  final _titleFocusNode = FocusNode();
  final _amountFocusNode = FocusNode();
  final _accountFocusNode = FocusNode();
  final _categoryFocusNode = FocusNode();
  final _notesFocusNode = FocusNode();
  // FORM VARIABLES
  TransactionType _selectedType = TransactionType.expense;
  Account? _selectedAccount;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  List<Account> _accounts = [];
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _accounts = List.from(widget.accounts);
    _categories = List.from(widget.categories);
    // If editing, populate fields
    if (widget.transaction != null) {
      _populateFieldsForEditing();
    } else {
      _initializeForNewTransaction();
    }
  }

  void _populateFieldsForEditing() {
    final transaction = widget.transaction!;
    _titleController.text = transaction.title;
    _amountController.text = transaction.amount.toString();
    _notesController.text = transaction.notes ?? '';
    _selectedType = transaction.type;
    _selectedDate = transaction.date;
    _selectedTime = TimeOfDay.fromDateTime(transaction.time);
    _selectedAccount = _accounts.firstWhere(
      (acc) => acc.id == transaction.accountId,
      orElse: () => _accounts.first,
    );
    _selectedCategory = _categories.firstWhere(
      (cat) => cat.id == transaction.categoryId,
      orElse: () => _categories.first,
    );
  }

  void _initializeForNewTransaction() {
    if (_accounts.isNotEmpty) {
      _selectedAccount = _accounts.first;
    }
    if (_categories.isNotEmpty) {
      _selectedCategory = _categories.firstWhere(
        (cat) => cat.type == CategoryType.expense,
        orElse: () => _categories.first,
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
    _accountFocusNode.dispose();
    _categoryFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccount == null) {
      _showError('Please select or add an account first');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Please select or add a category first');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final DateTime combinedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final transaction = Transaction(
        id: widget.transaction?.id, // null for new, existing id for edit
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        date: _selectedDate,
        time: combinedDateTime,
        type: _selectedType,
        accountId: _selectedAccount!.id!,
        categoryId: _selectedCategory!.id!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (widget.transaction == null) {
        await _dbHelper.insertTransaction(transaction);
      } else {
        await _dbHelper.updateTransaction(transaction);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.transaction == null
                  ? 'Transaction added successfully!'
                  : 'Transaction updated successfully!',
            ),
            backgroundColor: _selectedType == TransactionType.income
                ? const Color(0xFF2E7D32)
                : const Color(0xFFD32F2F),
          ),
        );
      }
    } catch (e) {
      _showError('Error saving transaction: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF1A237E)),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF1A237E)),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  List<Category> get _filteredCategories {
    final targetType = _selectedType == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    return _categories.where((cat) => cat.type == targetType).toList();
  }

  // INLINE ACCOUNT ADDITION
  Future<void> _addNewAccount() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditAccountScreen()),
    );
    if (result == true) {
      // Refresh accounts list
      final newAccounts = await _dbHelper.getAccounts();
      setState(() {
        _accounts = newAccounts;
        if (_selectedAccount == null && _accounts.isNotEmpty) {
          _selectedAccount = _accounts.last; // Select the newly added account
        }
      });
    }
  }

  // INLINE CATEGORY ADDITION
  Future<void> _addNewCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(
          type: _selectedType == TransactionType.income
              ? CategoryType.income
              : CategoryType.expense,
        ),
      ),
    );
    if (result == true) {
      // Refresh categories list
      final newCategories = await _dbHelper.getCategories();
      setState(() {
        _categories = newCategories;
        final filtered = _filteredCategories;
        if (_selectedCategory == null && filtered.isNotEmpty) {
          _selectedCategory = filtered.last; // Select the newly added category
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
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
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveTransaction,
              child: Text(
                'Save',
                style: TextStyle(
                  color: Theme.of(context).appBarTheme.foregroundColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TRANSACTION TYPE TOGGLE
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[100]!, Colors.grey[50]!],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: _selectedType == TransactionType.income
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF2E7D32),
                                      Color(0xFF4CAF50),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _selectedType == TransactionType.income
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2E7D32,
                                      ).withOpacity(0.3),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: _selectedType == TransactionType.income
                                    ? Colors.white
                                    : const Color(0xFF2E7D32),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Income',
                                style: TextStyle(
                                  color: _selectedType == TransactionType.income
                                      ? Colors.white
                                      : const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w700,
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: _selectedType == TransactionType.expense
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFD32F2F),
                                      Color(0xFFEF5350),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _selectedType == TransactionType.expense
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFD32F2F,
                                      ).withOpacity(0.3),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.remove_circle_outline,
                                color: _selectedType == TransactionType.expense
                                    ? Colors.white
                                    : const Color(0xFFD32F2F),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Expense',
                                style: TextStyle(
                                  color:
                                      _selectedType == TransactionType.expense
                                      ? Colors.white
                                      : const Color(0xFFD32F2F),
                                  fontWeight: FontWeight.w700,
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
              const SizedBox(height: 32),
              // TITLE FIELD
              _buildInputField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                label: 'Transaction Title',
                hint: 'e.g., Morning Coffee, Salary, Groceries',
                icon: Icons.edit_rounded,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_amountFocusNode),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter transaction title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // AMOUNT FIELD
              _buildInputField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                label: 'Amount',
                hint: '0.00',
                icon: Icons.currency_rupee_rounded,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_accountFocusNode),
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
              const SizedBox(height: 24),
              // ACCOUNT DROPDOWN WITH ADD OPTION
              _buildAccountSelector(),
              const SizedBox(height: 24),
              // CATEGORY DROPDOWN WITH ADD OPTION
              _buildCategorySelector(),
              const SizedBox(height: 24),
              // DATE AND TIME SELECTORS
              Row(
                children: [
                  Expanded(child: _buildDateSelector()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTimeSelector()),
                ],
              ),
              const SizedBox(height: 24),
              // NOTES FIELD
              _buildInputField(
                controller: _notesController,
                focusNode: _notesFocusNode,
                label: 'Notes (Optional)',
                hint: 'Add any additional details...',
                icon: Icons.note_alt_rounded,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),
              const SizedBox(height: 40),
              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedType == TransactionType.income
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor:
                        (_selectedType == TransactionType.income
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFD32F2F))
                            .withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEditing
                                  ? Icons.save_rounded
                                  : (_selectedType == TransactionType.income
                                        ? Icons.add_circle_outline
                                        : Icons.remove_circle_outline),
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isEditing
                                  ? 'Update Transaction'
                                  : 'Add ${_selectedType == TransactionType.income ? 'Income' : 'Expense'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // FIXED ACCOUNT SELECTOR
  Widget _buildAccountSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[50],
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _accounts.isEmpty
          ? Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No accounts found',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _addNewAccount,
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Account'),
                  ),
                ],
              ),
            )
          : DropdownButtonFormField<Account>(
              initialValue: _selectedAccount,
              focusNode: _accountFocusNode,
              decoration: InputDecoration(
                labelText: 'Account',
                prefixIcon: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF1A237E),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF1A237E),
                  ),
                  onPressed: _addNewAccount,
                  tooltip: 'Add New Account',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              items: _accounts.map((account) {
                return DropdownMenuItem<Account>(
                  value: account,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getAccountIcon(account.subType),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          account.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${NumberFormat('#,###').format(account.balance)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: account.balance >= 0
                              ? Colors.green[600]
                              : Colors.red[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedAccount = value);
                if (value != null) {
                  FocusScope.of(context).requestFocus(_categoryFocusNode);
                }
              },
            ),
    );
  }

  // FIXED CATEGORY SELECTOR (only one version)
  Widget _buildCategorySelector() {
    final filteredCategories = _filteredCategories;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[50],
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: filteredCategories.isEmpty
          ? Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No ${_selectedType == TransactionType.income ? 'income' : 'expense'} categories found',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _addNewCategory,
                    icon: const Icon(Icons.add),
                    label: Text(
                      'Add ${_selectedType == TransactionType.income ? 'Income' : 'Expense'} Category',
                    ),
                  ),
                ],
              ),
            )
          : DropdownButtonFormField<Category>(
              initialValue: _selectedCategory,
              focusNode: _categoryFocusNode,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(
                  Icons.category,
                  color: Color(0xFF1A237E),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF1A237E),
                  ),
                  onPressed: _addNewCategory,
                  tooltip: 'Add New Category',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              items: filteredCategories.map((category) {
                return DropdownMenuItem<Category>(
                  value: category,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(category.color.replaceAll('#', '0xFF')),
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            category.icon,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value);
                if (value != null) {
                  FocusScope.of(context).requestFocus(_notesFocusNode);
                }
              },
            ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[50],
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF1A237E),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Date',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
      ),
    );
  }

  Widget _buildTimeSelector() {
    return InkWell(
      onTap: _pickTime,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[50],
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Color(0xFF1A237E),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Time',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _selectedTime.format(context),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A237E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getAccountIcon(AccountSubType subType) {
    IconData iconData;
    Color iconColor;
    switch (subType) {
      case AccountSubType.bank:
        iconData = Icons.account_balance;
        iconColor = Colors.blue[700]!;
        break;
      case AccountSubType.cash:
        iconData = Icons.money;
        iconColor = Colors.green[700]!;
        break;
      case AccountSubType.digitalWallet:
        iconData = Icons.wallet;
        iconColor = Colors.purple[700]!;
        break;
      case AccountSubType.creditCard:
        iconData = Icons.credit_card;
        iconColor = Colors.orange[700]!;
        break;
      case AccountSubType.loan:
        iconData = Icons.receipt_long;
        iconColor = Colors.red[700]!;
        break;
      default:
        iconData = Icons.account_balance_wallet;
        iconColor = Colors.grey[700]!;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(iconData, color: iconColor, size: 16),
    );
  }
}
