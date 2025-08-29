import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/enums.dart';
import '../widgets/account/account_summary_cards.dart';
import '../widgets/credit_card/credit_card_summary_widget.dart';
import '../widgets/account/account_tile_widget.dart';
import '../widgets/account/account_actions_sheet.dart';
import '../widgets/forms/add_edit_account_screen.dart';

class AccountsScreen extends StatefulWidget {
  final VoidCallback? onAccountChanged;
  const AccountsScreen({super.key, this.onAccountChanged});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Account> _accounts = [];
  bool _isLoading = true;

  // Track which cards have already shown utilization warnings this session
  final Set<int> _shownUtilizationWarnings = <int>{};

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCreditUtilizationAlerts();
    });
  }

  Future<void> _loadAccounts() async {
    try {
      if (mounted) setState(() => _isLoading = true);

      final accounts = await _dbHelper.getAccounts();

      if (!mounted) return; // ← ADD THIS
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // ← AND ALSO HERE
      setState(() => _isLoading = false);
    }
  }

  void _showCreditUtilizationAlerts() {
    final creditCards = _accounts
        .where((account) => account.subType == AccountSubType.creditCard)
        .toList();

    for (final card in creditCards) {
      if (card.creditLimit != null && card.outstandingAmount != null) {
        final utilization = card.outstandingAmount! / card.creditLimit!;

        // Only show warning if we haven't shown it for this card this session
        if (!_shownUtilizationWarnings.contains(card.id)) {
          if (utilization > 0.6) {
            _shownUtilizationWarnings.add(card.id!); // Mark as shown
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'HIGH USAGE: ${card.name} utilization at ${(utilization * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red[700],
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () => _editAccount(card),
                ),
              ),
            );
          } else if (utilization > 0.3) {
            _shownUtilizationWarnings.add(card.id!); // Mark as shown
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'MODERATE USAGE: ${card.name} utilization at ${(utilization * 100).toStringAsFixed(1)}%',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange[700],
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () => _editAccount(card),
                ),
              ),
            );
          }
        }
      }
    }
  }

  void _addNewAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAccountScreen(
          onAccountChanged: () {
            _loadAccounts();
            widget.onAccountChanged?.call();
          },
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadAccounts();
        widget.onAccountChanged?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  void _editAccount(Account account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAccountScreen(
          account: account,
          onAccountChanged: widget.onAccountChanged,
        ),
      ),
    ).then((_) => _loadAccounts());
  }

  void _showAccountActions(Account account) async {
    final categories = await _dbHelper.getCategories();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AccountActionsSheet(
        account: account,
        accounts: _accounts,
        categories: categories,
        onAccountUpdated: _loadAccounts,
        onEditAccount: () => _editAccount(account),
        onDeleteAccount: () => _deleteAccount(account),
      ),
    );
  }

  Future<void> _deleteAccount(Account account) async {
    final db = await _dbHelper.database;
    final transactionCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE accountId = ?',
      [account.id],
    );

    final hasTransactions = (transactionCount.first['count'] as int) > 0;

    if (hasTransactions) {
      final deleteOption = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete "${account.name}"?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This account has ${transactionCount.first['count']} transactions.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose deletion option:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'account_only'),
              child: const Text(
                'Account Only',
                style: TextStyle(color: Colors.orange),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'with_transactions'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Account + Transactions'),
            ),
          ],
        ),
      );

      if (deleteOption == 'account_only') {
        await db.update(
          'accounts',
          {'isActive': 0},
          where: 'id = ?',
          whereArgs: [account.id],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${account.name} deactivated. Transactions preserved.',
              ),
            ),
          );
        }
      } else if (deleteOption == 'with_transactions') {
        await db.delete(
          'transactions',
          where: 'accountId = ?',
          whereArgs: [account.id],
        );
        await db.update(
          'accounts',
          {'isActive': 0},
          where: 'id = ?',
          whereArgs: [account.id],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${account.name} and all transactions deleted.'),
            ),
          );
        }
      }

      if (deleteOption != 'cancel') {
        _loadAccounts();
        widget.onAccountChanged?.call();
      }
    } else {
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
        await _dbHelper.deleteAccount(account.id!);
        _loadAccounts();
        widget.onAccountChanged?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${account.name} deleted successfully')),
          );
        }
      }
    }
  }

  @override
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

      // ---------- BODY --------------------------------------------------------
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAccounts,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  AccountSummaryCards(accounts: _accounts),
                  const SizedBox(height: 24),
                  CreditCardSummaryWidget(accounts: _accounts),
                  const SizedBox(height: 24),
                  _buildAccountsList(), // ← your long grouped-list method
                ],
              ),
            ),
    );
  }

  Widget _buildAccountsList() {
    // Group accounts by type
    final assetAccounts = _accounts
        .where((acc) => acc.type == AccountType.asset)
        .toList();
    final creditCards = _accounts
        .where((acc) => acc.subType == AccountSubType.creditCard)
        .toList();
    final otherLiabilities = _accounts
        .where(
          (acc) =>
              acc.type == AccountType.liability &&
              acc.subType != AccountSubType.creditCard,
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Accounts',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 16),

        if (_accounts.isEmpty)
          _buildEmptyState()
        else ...[
          // Asset Accounts Section
          if (assetAccounts.isNotEmpty) ...[
            _buildSectionHeader('💰 Asset Accounts', assetAccounts.length),
            const SizedBox(height: 8),
            ...assetAccounts.map(
              (account) => AccountTileWidget(
                account: account,
                onTap: () => _showAccountActions(account),
                onLongPress: () => _showAccountActions(account),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Credit Cards Section
          if (creditCards.isNotEmpty) ...[
            _buildSectionHeader('💳 Credit Cards', creditCards.length),
            const SizedBox(height: 8),
            ...creditCards.map(
              (account) => AccountTileWidget(
                account: account,
                onTap: () => _showAccountActions(account),
                onLongPress: () => _showAccountActions(account),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Other Liabilities Section
          if (otherLiabilities.isNotEmpty) ...[
            _buildSectionHeader('📋 Liabilities', otherLiabilities.length),
            const SizedBox(height: 8),
            ...otherLiabilities.map(
              (account) => AccountTileWidget(
                account: account,
                onTap: () => _showAccountActions(account),
                onLongPress: () => _showAccountActions(account),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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
}
