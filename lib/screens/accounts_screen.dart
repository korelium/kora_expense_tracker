import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/enums.dart';
import 'add_transaction_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Account> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      setState(() => _isLoading = true);
      final accounts = await _dbHelper.getAccounts();
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading accounts: $e');
      setState(() => _isLoading = false);
    }
  }

  double get _totalBalance {
    return _accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  double get _totalAssets {
    return _accounts
        .where((account) => account.type == AccountType.asset)
        .fold(0.0, (sum, account) => sum + account.balance);
  }

  double get _totalLiabilities {
    return _accounts
        .where((account) => account.type == AccountType.liability)
        .fold(0.0, (sum, account) => sum + (account.outstandingAmount ?? 0.0));
  }

  void _addNewAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditAccountScreen()),
    ).then((_) => _loadAccounts());
  }

  void _editAccount(Account account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAccountScreen(account: account),
      ),
    ).then((_) => _loadAccounts());
  }

  // ENHANCED: Show account action options (Income/Expense/Edit)
  void _showAccountActions(Account account) async {
    final categories = await _dbHelper.getCategories();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              account.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            // ADD INCOME
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add_circle_outline, color: Colors.green[700]),
              ),
              title: const Text('Add Income'),
              subtitle: const Text('Record money coming in'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTransactionScreen(
                      accounts: _accounts,
                      categories: categories,
                    ),
                  ),
                ).then((_) => _loadAccounts());
              },
            ),

            // ADD EXPENSE
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red[700],
                ),
              ),
              title: const Text('Add Expense'),
              subtitle: const Text('Record money going out'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTransactionScreen(
                      accounts: _accounts,
                      categories: categories,
                    ),
                  ),
                ).then((_) => _loadAccounts());
              },
            ),

            // EDIT ACCOUNT
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit, color: Colors.blue[700]),
              ),
              title: const Text('Edit Account'),
              subtitle: const Text('Modify account details'),
              onTap: () {
                Navigator.pop(context);
                _editAccount(account);
              },
            ),

            // DELETE ACCOUNT
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete, color: Colors.red[700]),
              ),
              title: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('Remove account permanently'),
              onTap: () {
                Navigator.pop(context);
                _deleteAccount(account);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${account.name}"?'),
            const SizedBox(height: 8),
            const Text(
              'This will also delete all transactions associated with this account.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.deleteAccount(account.id!);
        _loadAccounts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${account.name} deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting account: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _addNewAccount,
            icon: const Icon(Icons.add),
            tooltip: 'Add Account',
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAccounts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    _buildAccountsList(),
                  ],
                ),
              ),
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: _addNewAccount,
        backgroundColor: Theme.of(
          context,
        ).floatingActionButtonTheme.backgroundColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3F51B5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A237E).withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Net Worth',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '₹${NumberFormat('#,##,###.##').format(_totalBalance)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_accounts.length} accounts',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_up, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Assets',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${NumberFormat('#,##,###.##').format(_totalAssets)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD32F2F), Color(0xFFE57373)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD32F2F).withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.trending_down,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Liabilities',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${NumberFormat('#,##,###.##').format(_totalLiabilities)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Accounts',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            TextButton.icon(
              onPressed: _addNewAccount,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Account'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_accounts.isEmpty)
          _buildEmptyState()
        else
          ..._accounts.map((account) => _buildAccountTile(account)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No accounts yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first account to start tracking your finances',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addNewAccount,
            icon: const Icon(Icons.add),
            label: const Text('Add Account'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(Account account) {
    final isLiability = account.type == AccountType.liability;
    final displayBalance = isLiability
        ? (account.outstandingAmount ?? 0.0)
        : account.balance;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _getAccountIcon(account.subType),
        title: Text(
          account.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _getAccountSubtypeLabel(account.subType),
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            if (isLiability && account.creditLimit != null)
              Text(
                'Credit Limit: ₹${NumberFormat('#,##,###.##').format(account.creditLimit)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${NumberFormat('#,##,###.##').format(displayBalance)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isLiability ? Colors.red[700] : Colors.green[700],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isLiability ? 'Outstanding' : 'Balance',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        // ENHANCED: Tap to show account actions (Income/Expense/Edit)
        onTap: () => _showAccountActions(account),
        onLongPress: () => _showAccountActions(account),
      ),
    );
  }

  Widget _getAccountIcon(AccountSubType subType) {
    IconData accountIcon;
    Color iconColor;

    switch (subType) {
      case AccountSubType.bank:
        accountIcon = Icons.account_balance;
        iconColor = Colors.blue[700]!;
        break;
      case AccountSubType.cash:
        accountIcon = Icons.money;
        iconColor = Colors.green[700]!;
        break;
      case AccountSubType.digitalWallet:
        accountIcon = Icons.wallet;
        iconColor = Colors.purple[700]!;
        break;
      case AccountSubType.creditCard:
        accountIcon = Icons.credit_card;
        iconColor = Colors.orange[700]!;
        break;
      case AccountSubType.loan:
        accountIcon = Icons.receipt_long;
        iconColor = Colors.red[700]!;
        break;
      default:
        accountIcon = Icons.account_balance_wallet;
        iconColor = Colors.grey[700]!;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(accountIcon, color: iconColor, size: 24),
    );
  }

  String _getAccountSubtypeLabel(AccountSubType subType) {
    switch (subType) {
      case AccountSubType.bank:
        return 'Bank Account';
      case AccountSubType.cash:
        return 'Cash';
      case AccountSubType.digitalWallet:
        return 'Digital Wallet';
      case AccountSubType.creditCard:
        return 'Credit Card';
      case AccountSubType.loan:
        return 'Loan';
      case AccountSubType.debt:
        return 'Debt';
      case AccountSubType.investment:
        return 'Investment';
    }
  }
}

// ADD/EDIT ACCOUNT SCREEN WITH BALANCE ADJUSTMENT CONFIRMATION
class AddEditAccountScreen extends StatefulWidget {
  final Account? account;

  const AddEditAccountScreen({super.key, this.account});

  @override
  State<AddEditAccountScreen> createState() => _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends State<AddEditAccountScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _outstandingController = TextEditingController();
  // Credit Card specific controllers
  final _bankNameController = TextEditingController();
  final _cardTypeController = TextEditingController();
  final _cardCategoryController = TextEditingController();
  final _last6DigitsController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _rewardRateController = TextEditingController();
  final _annualFeeController = TextEditingController();
  final _foreignFeeController = TextEditingController();
  final _minPaymentController = TextEditingController();

  // Credit Card dropdowns
  String _selectedBankName = 'HDFC Bank';
  String _selectedCardType = 'Visa';
  String _selectedCardCategory = 'Rewards';
  String _selectedCardStatus = 'Active';
  int? _billingDate;
  int? _dueDate;

  // Indian Banks
  final List<String> _indianBanks = [
    'HDFC Bank',
    'ICICI Bank',
    'State Bank of India',
    'Axis Bank',
    'Kotak Mahindra Bank',
    'Yes Bank',
    'IndusInd Bank',
    'IDFC First Bank',
    'RBL Bank',
    'Standard Chartered',
    'Citibank',
    'HSBC',
    'American Express',
    'Punjab National Bank',
    'Bank of Baroda',
    'Canara Bank',
    'Union Bank',
  ];

  final List<String> _cardTypes = [
    'Visa',
    'MasterCard',
    'American Express',
    'RuPay',
    'Diners Club',
  ];
  final List<String> _cardCategories = [
    'Rewards',
    'Cashback',
    'Travel',
    'Fuel',
    'Shopping',
    'Dining',
    'Premium',
  ];
  final List<String> _cardStatuses = ['Active', 'Inactive', 'Blocked', 'Lost'];

  AccountType _selectedType = AccountType.asset;
  AccountSubType _selectedSubType = AccountSubType.bank;
  String _selectedCurrency = 'INR';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize credit card fields if editing
    if (widget.account != null && widget.account!.creditCardDetails != null) {
      final cardDetails = widget.account!.creditCardDetails!;
      _bankNameController.text = cardDetails.bankName ?? '';
      _selectedBankName = cardDetails.bankName ?? 'HDFC Bank';
      _selectedCardType = cardDetails.cardType ?? 'Visa';
      _selectedCardCategory = cardDetails.cardCategory ?? 'Rewards';
      _selectedCardStatus = cardDetails.cardStatus ?? 'Active';
      _last6DigitsController.text = cardDetails.last6Digits ?? '';
      _expiryDateController.text = cardDetails.expiryDate ?? '';
      _rewardRateController.text = cardDetails.rewardRate ?? '';
      _annualFeeController.text = cardDetails.annualFee?.toString() ?? '';
      _foreignFeeController.text =
          cardDetails.foreignTransactionFee?.toString() ?? '';
      _minPaymentController.text =
          cardDetails.minPaymentAmount?.toString() ?? '';
      _billingDate = cardDetails.billingDate;
      _dueDate = cardDetails.dueDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _creditLimitController.dispose();
    _outstandingController.dispose();
    super.dispose();
  }

  // ENHANCED: Balance adjustment confirmation
  Future _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      CreditCardDetails? creditCardDetails;

      // Create credit card details if it's a credit card
      if (_selectedSubType == AccountSubType.creditCard) {
        creditCardDetails = CreditCardDetails(
          last6Digits: _last6DigitsController.text.trim().isEmpty
              ? null
              : _last6DigitsController.text.trim(),
          bankName: _selectedBankName,
          cardType: _selectedCardType,
          cardCategory: _selectedCardCategory,
          cardStatus: _selectedCardStatus,
          expiryDate: _expiryDateController.text.trim().isEmpty
              ? null
              : _expiryDateController.text.trim(),
          billingDate: _billingDate,
          dueDate: _dueDate,
          minPaymentAmount: _minPaymentController.text.trim().isEmpty
              ? null
              : double.tryParse(_minPaymentController.text.trim()),
          rewardRate: _rewardRateController.text.trim().isEmpty
              ? null
              : _rewardRateController.text.trim(),
          annualFee: _annualFeeController.text.trim().isEmpty
              ? null
              : double.tryParse(_annualFeeController.text.trim()),
          foreignTransactionFee: _foreignFeeController.text.trim().isEmpty
              ? null
              : double.tryParse(_foreignFeeController.text.trim()),
        );
      }

      final account = Account(
        id: widget.account?.id,
        name: _nameController.text.trim(),
        type: _selectedType,
        subType: _selectedSubType,
        balance: double.parse(_balanceController.text.trim()),
        creditLimit: _creditLimitController.text.isNotEmpty
            ? double.parse(_creditLimitController.text.trim())
            : null,
        outstandingAmount: _outstandingController.text.isNotEmpty
            ? double.parse(_outstandingController.text.trim())
            : null,
        currency: _selectedCurrency,
        creditCardDetails: creditCardDetails,
      );

      // Rest of existing logic...
      bool shouldCreateAdjustment = false;
      if (widget.account != null) {
        final balanceDifference = account.balance - widget.account!.balance;
        if (balanceDifference != 0) {
          final shouldAdjust = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Balance Changed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance changed by ₹${NumberFormat('#,##,###.##').format(balanceDifference.abs())}',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Would you like to create an adjustment transaction to reflect this change?',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No, just update balance'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes, create adjustment'),
                ),
              ],
            ),
          );
          shouldCreateAdjustment = shouldAdjust ?? false;
        }
      }

      if (widget.account == null) {
        await _dbHelper.insertAccount(account);
      } else {
        await _dbHelper.updateAccount(
          account,
          adjustBalance: shouldCreateAdjustment,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.account == null
                  ? 'Account created successfully!'
                  : 'Account updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Account' : 'Add Account'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
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
              onPressed: _saveAccount,
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

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  hintText: 'e.g., HDFC Savings, Cash Wallet',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_circle),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter account name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<AccountType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: AccountType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type == AccountType.asset ? 'Asset' : 'Liability',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    if (_selectedType == AccountType.asset) {
                      _selectedSubType = AccountSubType.bank;
                    } else {
                      _selectedSubType = AccountSubType.creditCard;
                    }
                  });
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<AccountSubType>(
                initialValue: _selectedSubType,
                decoration: const InputDecoration(
                  labelText: 'Account Sub-Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
                items: _getSubTypeOptions().map((subType) {
                  return DropdownMenuItem(
                    value: subType,
                    child: Text(_getSubTypeLabel(subType)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedSubType = value!);
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: _selectedType == AccountType.asset
                      ? 'Current Balance'
                      : 'Current Balance',
                  hintText: '0.00',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter balance';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // CREDIT CARD SPECIFIC FIELDS
              if (_selectedSubType == AccountSubType.creditCard) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.credit_card, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Credit Card Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedBankName,
                        decoration: const InputDecoration(
                          labelText: 'Bank Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_balance),
                        ),
                        items: _indianBanks
                            .map(
                              (bank) => DropdownMenuItem(
                                value: bank,
                                child: Text(bank),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedBankName = value!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCardType,
                              decoration: const InputDecoration(
                                labelText: 'Card Type *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.credit_card),
                              ),
                              items: _cardTypes
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedCardType = value!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCardCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.category),
                              ),
                              items: _cardCategories
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setState(
                                () => _selectedCardCategory = value!,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _last6DigitsController,
                              decoration: const InputDecoration(
                                labelText: 'Last 6 Digits (Optional)',
                                hintText: '●●●●●● 1234',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.numbers),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCardStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.info),
                              ),
                              items: _cardStatuses
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedCardStatus = value!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _expiryDateController,
                              decoration: const InputDecoration(
                                labelText: 'Expiry Date (MM/YY)',
                                hintText: '12/28',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.date_range),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _minPaymentController,
                              decoration: const InputDecoration(
                                labelText: 'Min Payment',
                                hintText: '₹ 2,000',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.payment),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _rewardRateController,
                              decoration: const InputDecoration(
                                labelText: 'Reward Rate',
                                hintText: '2 pts/₹100',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.card_giftcard),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _annualFeeController,
                              decoration: const InputDecoration(
                                labelText: 'Annual Fee',
                                hintText: '₹ 2,999',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.monetization_on),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _foreignFeeController,
                        decoration: const InputDecoration(
                          labelText: 'Foreign Transaction Fee (%)',
                          hintText: '3.5',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.public),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _billingDate,
                              decoration: const InputDecoration(
                                labelText: 'Billing Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              hint: const Text('Select Day'),
                              items: List.generate(31, (i) => i + 1)
                                  .map(
                                    (day) => DropdownMenuItem(
                                      value: day,
                                      child: Text('${day}th'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _billingDate = value),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _dueDate,
                              decoration: const InputDecoration(
                                labelText: 'Due Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.schedule),
                              ),
                              hint: const Text('Select Day'),
                              items: List.generate(31, (i) => i + 1)
                                  .map(
                                    (day) => DropdownMenuItem(
                                      value: day,
                                      child: Text('${day}th'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _dueDate = value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // ],
              DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                items: const [
                  DropdownMenuItem(value: 'INR', child: Text('INR (₹)')),
                  DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                ],
                onChanged: (value) {
                  setState(() => _selectedCurrency = value!);
                },
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAccount,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEditing ? 'Update Account' : 'Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<AccountSubType> _getSubTypeOptions() {
    if (_selectedType == AccountType.asset) {
      return [
        AccountSubType.bank,
        AccountSubType.cash,
        AccountSubType.digitalWallet,
        AccountSubType.investment,
      ];
    } else {
      return [
        AccountSubType.creditCard,
        AccountSubType.loan,
        AccountSubType.debt,
      ];
    }
  }

  String _getSubTypeLabel(AccountSubType subType) {
    switch (subType) {
      case AccountSubType.bank:
        return 'Bank Account';
      case AccountSubType.cash:
        return 'Cash';
      case AccountSubType.digitalWallet:
        return 'Digital Wallet';
      case AccountSubType.investment:
        return 'Investment';
      case AccountSubType.creditCard:
        return 'Credit Card';
      case AccountSubType.loan:
        return 'Loan';
      case AccountSubType.debt:
        return 'Other Debt';
    }
  }
}
