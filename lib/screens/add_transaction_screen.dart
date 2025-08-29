import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/enums.dart';
import '../models/transaction.dart';
import '../widgets/forms/add_edit_account_screen.dart'; // imported after the refactorting the app
import 'categories_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final List<Account> accounts;
  final List<Category> categories;
  final Transaction? transaction; // For editing existing transactions
  final Account? selectedAccount; // Pre-selected account
  final String? initialTransactionType; // Pre-selected transaction type

  const AddTransactionScreen({
    super.key,
    required this.accounts,
    required this.categories,
    this.transaction,
    this.selectedAccount,
    this.initialTransactionType,
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
  Account? _selectedToAccount; // For transfers
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
    // Validate selections after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateSelections();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh accounts and categories when dependencies change
    _refreshData();
  }

  Future<void> _refreshData() async {
    try {
      final accounts = await _dbHelper.getAccounts();
      final categories = await _dbHelper.getCategories();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _categories = categories;
      });
      // Re-initialize if no account/category was selected
      if (_selectedAccount == null && _accounts.isNotEmpty) {
        _selectedAccount = _accounts.first;
      }
      if (_selectedCategory == null && _categories.isNotEmpty) {
        _selectedCategory = _categories.firstWhere(
          (cat) => cat.type == CategoryType.expense,
          orElse: () => _categories.first,
        );
      }
      // Validate current selections are still in the updated lists
      if (_selectedAccount != null &&
          !_accounts.any((acc) => acc.id == _selectedAccount!.id)) {
        _selectedAccount = _accounts.isNotEmpty ? _accounts.first : null;
      }
      if (_selectedCategory != null &&
          !_categories.any((cat) => cat.id == _selectedCategory!.id)) {
        _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
      }
    } catch (e) {
      // Handle error silently
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
    _selectedAccount = _accounts.isNotEmpty
        ? _accounts.firstWhere(
            (acc) => acc.id == transaction.accountId,
            orElse: () => _accounts.first,
          )
        : null;
    _selectedCategory = _categories.isNotEmpty
        ? _categories.firstWhere(
            (cat) => cat.id == transaction.categoryId,
            orElse: () => _categories.first,
          )
        : null;
  }

  void _initializeForNewTransaction() {
    // Set pre-selected account if provided
    if (widget.selectedAccount != null && 
        _accounts.any((acc) => acc.id == widget.selectedAccount!.id)) {
      _selectedAccount = widget.selectedAccount;
    } else if (_accounts.isNotEmpty) {
      _selectedAccount = _accounts.first;
    }

    // Set initial transaction type if provided
    if (widget.initialTransactionType != null) {
      switch (widget.initialTransactionType!.toLowerCase()) {
        case 'income':
          _selectedType = TransactionType.income;
          break;
        case 'expense':
          _selectedType = TransactionType.expense;
          break;
        case 'transfer':
          _selectedType = TransactionType.transfer;
          break;
      }
    }

    // NO DEFAULT CATEGORY - User must select manually
    _selectedCategory = null;
  }

  void _validateSelections() {
    // Ensure selected account is still valid
    if (_selectedAccount != null &&
        !_accounts.any((acc) => acc.id == _selectedAccount!.id)) {
      _selectedAccount = _accounts.isNotEmpty ? _accounts.first : null;
    }
    // Ensure selected category is still valid
    if (_selectedCategory != null &&
        !_categories.any((cat) => cat.id == _selectedCategory!.id)) {
      _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
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

    // For transfers, check if destination account is selected
    if (_selectedType == TransactionType.transfer) {
      if (_selectedToAccount == null) {
        _showError('Please select destination account for transfer');
        return;
      }
      if (_selectedAccount!.id == _selectedToAccount!.id) {
        _showError('Source and destination accounts cannot be the same');
        return;
      }
    } else {
      // For income/expense, check if category is selected
      if (_selectedCategory == null) {
        _showError('Please select or add a category');
        return;
      }
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

      final amount = double.parse(_amountController.text.trim());
      final title = _titleController.text.trim();
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      if (_selectedType == TransactionType.transfer) {
        // Handle transfer: create two transactions
        // Get or create a transfer category
        final transferCategory = await _getOrCreateTransferCategory();

        // Create outgoing transaction (expense from source account)
        final outgoingTransaction = Transaction(
          title: 'Transfer to ${_selectedToAccount!.name}',
          amount: amount,
          date: _selectedDate,
          time: combinedDateTime,
          type: TransactionType.expense,
          accountId: _selectedAccount!.id!,
          categoryId: transferCategory.id!,
          notes: notes,
        );

        // Create incoming transaction (income to destination account)
        final incomingTransaction = Transaction(
          title: 'Transfer from ${_selectedAccount!.name}',
          amount: amount,
          date: _selectedDate,
          time: combinedDateTime,
          type: TransactionType.income,
          accountId: _selectedToAccount!.id!,
          categoryId: transferCategory.id!,
          notes: notes,
        );

        // Insert both transactions
        await _dbHelper.insertTransaction(outgoingTransaction);
        await _dbHelper.insertTransaction(incomingTransaction);

        // Update both account balances
        await _dbHelper.updateAccountBalance(_selectedAccount!.id!);
        await _dbHelper.updateAccountBalance(_selectedToAccount!.id!);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Transfer of ₹${NumberFormat('#,###').format(amount)} completed successfully!',
              ),
              backgroundColor: const Color(0xFF1565C0),
            ),
          );
        }
      } else {
        // Handle regular income/expense transaction
        final transaction = Transaction(
          id: widget.transaction?.id,
          title: title,
          amount: amount,
          date: _selectedDate,
          time: combinedDateTime,
          type: _selectedType,
          accountId: _selectedAccount!.id!,
          categoryId: _selectedCategory!.id!,
          notes: notes,
        );

        if (widget.transaction == null) {
          await _dbHelper.insertTransaction(transaction);
          await _dbHelper.updateAccountBalance(_selectedAccount!.id!);
        } else {
          await _dbHelper.updateTransaction(transaction);
          await _dbHelper.updateAccountBalance(_selectedAccount!.id!);
        }

        if (mounted) {
          Navigator.pop(context, true);
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
      }
    } catch (e) {
      _showError('Error saving transaction: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper method to get or create a transfer category
  Future<Category> _getOrCreateTransferCategory() async {
    // Try to find existing transfer category
    final existingCategory = _categories.firstWhere(
      (cat) => cat.name.toLowerCase().contains('transfer'),
      orElse: () => Category(
        name: 'Transfer',
        type: CategoryType.expense, // Default type
        icon: '🔄',
        color: '#1565C0',
      ),
    );

    // If category doesn't exist in database, create it
    if (existingCategory.id == null) {
      final categoryId = await _dbHelper.insertCategory(existingCategory);
      return existingCategory.copyWith(id: categoryId);
    }

    return existingCategory;
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
    if (date != null && mounted) {
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
    if (time != null && mounted) {
      setState(() => _selectedTime = time);
    }
  }

  // to show the credit card balence 0 without - sysmbol
  String _formatCreditCardBalance(double outstandingAmount) {
    if (outstandingAmount == 0) {
      return '₹0'; // No minus for zero balance
    } else if (outstandingAmount > 0) {
      return '-₹${NumberFormat('#,###').format(outstandingAmount)}'; // Show debt as negative
    } else {
      return '₹${NumberFormat('#,###').format(outstandingAmount.abs())}'; // Show credit as positive
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
      MaterialPageRoute(
        builder: (context) => const AddEditAccountScreen(),
      ),
    );
    
    if (result == true) {
      // Refresh accounts list immediately
      final newAccounts = await _dbHelper.getAccounts();
      if (!mounted) return;
      
      setState(() {
        _accounts = newAccounts;
        // Select the newly added account (last in the list)
        if (_accounts.isNotEmpty) {
          _selectedAccount = _accounts.last;
        }
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Account added! Selected: ${_selectedAccount?.name ?? 'New Account'}'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
      if (!mounted) return;
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

    // Ensure we have valid selections before building
    if (_accounts.isNotEmpty &&
        (_selectedAccount == null ||
            !_accounts.any((acc) => acc.id == _selectedAccount!.id))) {
      _selectedAccount = _accounts.first;
    }

    final filteredCategories = _filteredCategories;
    // NO AUTO-SELECTION - User must choose category manually

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
              // TRANSACTION TYPE TOGGLE WITH TRANSFER
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
                            _selectedToAccount = null; // Reset transfer account
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
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Income',
                                style: TextStyle(
                                  color: _selectedType == TransactionType.income
                                      ? Colors.white
                                      : const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
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
                            _selectedToAccount = null; // Reset transfer account
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
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Expense',
                                style: TextStyle(
                                  color:
                                      _selectedType == TransactionType.expense
                                      ? Colors.white
                                      : const Color(0xFFD32F2F),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
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
                            _selectedType = TransactionType.transfer;
                            _selectedCategory =
                                null; // No category for transfers
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: _selectedType == TransactionType.transfer
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF1565C0),
                                      Color(0xFF42A5F5),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _selectedType == TransactionType.transfer
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF1565C0,
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
                                Icons.swap_horiz,
                                color: _selectedType == TransactionType.transfer
                                    ? Colors.white
                                    : const Color(0xFF1565C0),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Transfer',
                                style: TextStyle(
                                  color:
                                      _selectedType == TransactionType.transfer
                                      ? Colors.white
                                      : const Color(0xFF1565C0),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
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
              // TO ACCOUNT SELECTOR (FOR TRANSFERS)
              if (_selectedType == TransactionType.transfer) ...[
                _buildToAccountSelector(),
                const SizedBox(height: 24),
              ],
              // CATEGORY DROPDOWN WITH ADD OPTION (SKIP FOR TRANSFERS)
              if (_selectedType != TransactionType.transfer) ...[
                _buildCategorySelector(),
                const SizedBox(height: 24),
              ],
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
    // Build-safe current selection (no setState here)
    final hasValidAccount =
        _selectedAccount != null &&
        _accounts.any((acc) => acc.id == _selectedAccount!.id);
    final currentAccount = hasValidAccount
        ? _selectedAccount
        : (_accounts.isNotEmpty ? _accounts.first : null);

    // Don't render dropdown if no valid selection
    if (currentAccount == null || _accounts.isEmpty) {
      return Container(
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
      );
    }

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
      child: DropdownButtonFormField<Account>(
        initialValue: currentAccount,
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
                  //here to change the trnsaction amount credit card balence
                  account.subType == AccountSubType.creditCard
                      ? _formatCreditCardBalance(account.outstandingAmount ?? 0)
                      : '₹${NumberFormat('#,###').format(account.balance)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: account.subType == AccountSubType.creditCard
                        ? (account.outstandingAmount ?? 0) > 0
                              ? Colors.red[600] // Red if you owe money
                              : Colors.green[600] // Green if no outstanding
                        : account.balance >= 0
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
          if (!mounted) return;
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

    // Build-safe current selection (no setState here)
    final hasValidCategory =
        _selectedCategory != null &&
        filteredCategories.any((cat) => cat.id == _selectedCategory!.id);
    final currentCategory = hasValidCategory
        ? _selectedCategory
        : (filteredCategories.isNotEmpty ? filteredCategories.first : null);

    // Don't render dropdown if no valid selection
    if (currentCategory == null || filteredCategories.isEmpty) {
      return Container(
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
      );
    }

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
      child: DropdownButtonFormField<Category>(
        initialValue: currentCategory,
        focusNode: _categoryFocusNode,
        decoration: InputDecoration(
          labelText: 'Category',
          prefixIcon: const Icon(Icons.category, color: Color(0xFF1A237E)),
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
          if (!mounted) return;
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

  // TO ACCOUNT SELECTOR FOR TRANSFERS
  Widget _buildToAccountSelector() {
    // Filter out the selected "from" account
    final availableAccounts = _accounts
        .where((acc) => acc.id != _selectedAccount?.id)
        .toList();

    if (availableAccounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, size: 48, color: Colors.orange[600]),
            const SizedBox(height: 12),
            Text(
              'Need at least 2 accounts for transfers',
              style: TextStyle(fontSize: 16, color: Colors.orange[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addNewAccount,
              icon: const Icon(Icons.add),
              label: const Text('Add Another Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

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
      child: DropdownButtonFormField<Account>(
        initialValue: _selectedToAccount,
        decoration: InputDecoration(
          labelText: 'Transfer To Account',
          prefixIcon: const Icon(Icons.call_received, color: Color(0xFF1565C0)),
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF1565C0),
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
        hint: const Text('Select destination account'),
        items: availableAccounts.map((account) {
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
                  account.subType == AccountSubType.creditCard
                      ? _formatCreditCardBalance(account.outstandingAmount ?? 0)
                      : '₹${NumberFormat('#,###').format(account.balance)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: account.subType == AccountSubType.creditCard
                        ? (account.outstandingAmount ?? 0) > 0
                              ? Colors.red[600]
                              : Colors.green[600]
                        : account.balance >= 0
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
          if (!mounted) return;
          setState(() => _selectedToAccount = value);
        },
        validator: (value) {
          if (_selectedType == TransactionType.transfer && value == null) {
            return 'Please select destination account';
          }
          return null;
        },
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
