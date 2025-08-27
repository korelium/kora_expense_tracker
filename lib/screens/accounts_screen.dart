import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/enums.dart';

// ACCOUNTS SCREEN - Manage all user accounts (bank, cash, credit cards, etc.)
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({Key? key}) : super(key: key);

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // DATA VARIABLES
  List<Account> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts(); // Load accounts when screen opens
  }

  // LOAD ACCOUNTS FROM DATABASE
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

  // CALCULATE TOTAL BALANCE FROM ALL ACCOUNTS
  double get _totalBalance {
    return _accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  // CALCULATE TOTAL ASSETS (positive balances)
  double get _totalAssets {
    return _accounts
        .where((account) => account.type == AccountType.asset)
        .fold(0.0, (sum, account) => sum + account.balance);
  }

  // CALCULATE TOTAL LIABILITIES (credit cards, loans)
  double get _totalLiabilities {
    return _accounts
        .where((account) => account.type == AccountType.liability)
        .fold(0.0, (sum, account) => sum + (account.outstandingAmount ?? 0.0));
  }

  // NAVIGATE TO ADD NEW ACCOUNT
  void _addNewAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditAccountScreen()),
    ).then((_) => _loadAccounts()); // Refresh accounts after adding
  }

  // NAVIGATE TO EDIT EXISTING ACCOUNT
  void _editAccount(Account account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAccountScreen(account: account),
      ),
    ).then((_) => _loadAccounts()); // Refresh accounts after editing
  }

  // DELETE ACCOUNT WITH CONFIRMATION
  Future<void> _deleteAccount(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "${account.name}"?'),
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
        _loadAccounts(); // Refresh accounts list
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
      // TOP APP BAR
      appBar: AppBar(
        title: const Text('Accounts'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // ADD ACCOUNT BUTTON
          IconButton(
            onPressed: _addNewAccount,
            icon: const Icon(Icons.add),
            tooltip: 'Add Account',
          ),
        ],
      ),

      // MAIN CONTENT
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
                    // SUMMARY CARDS - Show total balance, assets, liabilities
                    _buildSummaryCards(),

                    const SizedBox(height: 24),

                    // ACCOUNTS LIST SECTION
                    _buildAccountsList(),
                  ],
                ),
              ),
            ),

      // FLOATING ACTION BUTTON - Quick add account
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewAccount,
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // SUMMARY CARDS WIDGET - Shows total balance, assets, liabilities
  Widget _buildSummaryCards() {
    return Column(
      children: [
        // TOTAL BALANCE CARD
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
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
              const SizedBox(height: 8),
              Text(
                '₹${NumberFormat('#,##,###.##').format(_totalBalance)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_accounts.length} accounts',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ASSETS AND LIABILITIES ROW
        Row(
          children: [
            // ASSETS CARD
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: Colors.green[700],
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Assets',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${NumberFormat('#,##,###.##').format(_totalAssets)}',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // LIABILITIES CARD
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_down,
                          color: Colors.red[700],
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Liabilities',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${NumberFormat('#,##,###.##').format(_totalLiabilities)}',
                      style: TextStyle(
                        color: Colors.red[800],
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

  // ACCOUNTS LIST WIDGET - Shows all accounts
  Widget _buildAccountsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SECTION HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Accounts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: _addNewAccount,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Account'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ACCOUNTS LIST OR EMPTY STATE
        if (_accounts.isEmpty)
          _buildEmptyState()
        else
          ..._accounts.map((account) => _buildAccountTile(account)),
      ],
    );
  }

  // EMPTY STATE WIDGET - When no accounts exist
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
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

  // ACCOUNT TILE WIDGET - Individual account display
  Widget _buildAccountTile(Account account) {
    final isLiability = account.type == AccountType.liability;
    final displayBalance = isLiability
        ? (account.outstandingAmount ?? 0.0)
        : account.balance;

    // GET ACCOUNT ICON BASED ON SUBTYPE
    IconData accountIcon;
    Color iconColor;

    switch (account.subType) {
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),

        // ACCOUNT ICON
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(accountIcon, color: iconColor, size: 24),
        ),

        // ACCOUNT DETAILS
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

        // BALANCE
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
            if (isLiability)
              Text(
                'Outstanding',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              )
            else
              Text(
                'Balance',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
          ],
        ),

        // TAP TO EDIT
        onTap: () => _editAccount(account),

        // LONG PRESS TO DELETE
        onLongPress: () => _deleteAccount(account),
      ),
    );
  }

  // GET READABLE LABEL FOR ACCOUNT SUBTYPE
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

// ADD/EDIT ACCOUNT SCREEN - For creating and editing accounts
class AddEditAccountScreen extends StatefulWidget {
  final Account? account; // null for new account, existing account for editing

  const AddEditAccountScreen({Key? key, this.account}) : super(key: key);

  @override
  State<AddEditAccountScreen> createState() => _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends State<AddEditAccountScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  // FORM CONTROLLERS
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _outstandingController = TextEditingController();

  // FORM VARIABLES
  AccountType _selectedType = AccountType.asset;
  AccountSubType _selectedSubType = AccountSubType.bank;
  String _selectedCurrency = 'INR';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      // EDITING EXISTING ACCOUNT - Populate fields
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.toString();
      _selectedType = widget.account!.type;
      _selectedSubType = widget.account!.subType;
      _selectedCurrency = widget.account!.currency;

      if (widget.account!.creditLimit != null) {
        _creditLimitController.text = widget.account!.creditLimit.toString();
      }
      if (widget.account!.outstandingAmount != null) {
        _outstandingController.text = widget.account!.outstandingAmount
            .toString();
      }
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

  // SAVE ACCOUNT (CREATE OR UPDATE)
  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final account = Account(
        id: widget.account?.id, // null for new account
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
      );

      if (widget.account == null) {
        // CREATE NEW ACCOUNT
        await _dbHelper.insertAccount(account);
      } else {
        // UPDATE EXISTING ACCOUNT
        await _dbHelper.updateAccount(account);
      }

      if (mounted) {
        Navigator.pop(context); // Return to accounts screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.account == null
                  ? 'Account created successfully!'
                  : 'Account updated successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving account: $e')));
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
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
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
              // ACCOUNT NAME FIELD
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

              // ACCOUNT TYPE DROPDOWN
              DropdownButtonFormField<AccountType>(
                value: _selectedType,
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
                    // UPDATE SUBTYPE OPTIONS BASED ON TYPE
                    if (_selectedType == AccountType.asset) {
                      _selectedSubType = AccountSubType.bank;
                    } else {
                      _selectedSubType = AccountSubType.creditCard;
                    }
                  });
                },
              ),

              const SizedBox(height: 16),

              // ACCOUNT SUBTYPE DROPDOWN
              DropdownButtonFormField<AccountSubType>(
                value: _selectedSubType,
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

              // BALANCE/OUTSTANDING AMOUNT FIELD
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

              // CREDIT LIMIT FIELD (FOR CREDIT CARDS)
              if (_selectedSubType == AccountSubType.creditCard)
                Column(
                  children: [
                    TextFormField(
                      controller: _creditLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Credit Limit',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.credit_score),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (double.tryParse(value.trim()) == null) {
                            return 'Please enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _outstandingController,
                      decoration: const InputDecoration(
                        labelText: 'Outstanding Amount',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (double.tryParse(value.trim()) == null) {
                            return 'Please enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // CURRENCY DROPDOWN
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
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

              // SAVE BUTTON
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

  // GET AVAILABLE SUBTYPE OPTIONS BASED ON ACCOUNT TYPE
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

  // GET READABLE LABEL FOR SUBTYPE
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
