import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/enums.dart';
import 'accounts_screen.dart';
import 'add_transaction_screen.dart';
import 'transactions_list_screen.dart';
import 'settings_screen.dart';
import '../widgets/forms/add_edit_account_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  List<Category> _categories = [];
  double _totalBalance = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpenses = 0.0;
  bool _isLoading = true;
  int _selectedIndex = 0;

  // DOUBLE BACK PRESS VARIABLES
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final transactions = await _dbHelper.getTransactions();
      final accounts = await _dbHelper.getAccounts();
      print('🏦 Dashboard loaded ${accounts.length} accounts');
      final categories = await _dbHelper.getCategories();
      print('📂 Dashboard loaded ${categories.length} categories');

      _calculateTotals(transactions, accounts);
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _accounts = accounts;
          _categories = categories;
          _isLoading = false;
        });

        // Show credit utilization alerts after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showCreditUtilizationAlerts();
          }
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateTotals(
    List<Transaction> transactions,
    List<Account> accounts,
  ) {
    double totalAssets = 0.0;
    double totalLiabilities = 0.0;

    for (var account in accounts) {
      if (account.type == AccountType.asset) {
        totalAssets += account.balance;
      } else if (account.type == AccountType.liability) {
        // For credit cards, outstanding amount is the liability
        if (account.subType == AccountSubType.creditCard) {
          // Credit cards: outstanding amount is the liability (negative impact on net worth)
          totalLiabilities += (account.outstandingAmount ?? 0.0);
        } else {
          // Other liabilities (loans, debts)
          totalLiabilities += (account.outstandingAmount ?? account.balance);
        }
      }
    }

    _totalBalance =
        totalAssets - totalLiabilities; // Net worth = Assets - Liabilities

    // Monthly calculations remain the same
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    double monthlyIncome = 0.0;
    double monthlyExpenses = 0.0;

    for (var transaction in transactions) {
      if (transaction.date.isAfter(thisMonth)) {
        if (transaction.type == TransactionType.income) {
          monthlyIncome += transaction.amount;
        } else {
          monthlyExpenses += transaction.amount;
        }
      }
    }

    _monthlyIncome = monthlyIncome;
    _monthlyExpenses = monthlyExpenses;
  }

  void _onNavItemTapped(int index) {
    if (mounted) {
      setState(() => _selectedIndex = index);
      // Refresh data when switching to accounts tab
      if (index == 2) {
        _loadData();
      }
    }
  }

  // NEW: Method to get current screen content
  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const TransactionsListScreen();
      case 2:
        return AccountsScreen(onAccountChanged: _loadData);
      case 3:
        return const SettingsScreen();
      default:
        return _buildDashboardContent();
    }
  }

  // NEW: Dashboard content as a separate widget
  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 20),
            _buildMonthlySummary(),
            const SizedBox(height: 24),
            _buildCreditUtilizationSummary(),
            const SizedBox(height: 24),
            _buildRecentTransactions(),
          ],
        ),
      ),
    );
  }

  // NEW: Edit transaction from dashboard
  Future<void> _editTransactionFromDashboard(Transaction transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          accounts: _accounts,
          categories: _categories,
          transaction: transaction, // Pass transaction for editing
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('${transaction.title} updated successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // FIXED: Delete transaction from dashboard
  Future<void> _deleteTransactionFromDashboard(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete "${transaction.title}"?',
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
        await _dbHelper.deleteTransaction(transaction.id!);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${transaction.title} deleted successfully'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting transaction: $e')),
          );
        }
      }
    }
  }

  // NEW: Credit utilization alert system for dashboard
  void _showCreditUtilizationAlerts() {
    if (!mounted) return;
    
    final creditCards = _accounts
        .where((account) => account.subType == AccountSubType.creditCard)
        .toList();

    for (final card in creditCards) {
      if (card.creditLimit != null && card.outstandingAmount != null) {
        final utilization = card.outstandingAmount! / card.creditLimit!;

        if (utilization > 0.6) {
          // HIGH USAGE ALERT
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
                onPressed: () {
                  if (mounted) {
                    setState(() => _selectedIndex = 2); // Switch to accounts tab
                  }
                },
              ),
            ),
          );
        } else if (utilization > 0.3) {
          // MODERATE USAGE ALERT
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
                onPressed: () {
                  if (mounted) {
                    setState(() => _selectedIndex = 2); // Switch to accounts tab
                  }
                },
              ),
            ),
          );
        }
      }
    }
  }

  // DOUBLE BACK PRESS TO EXIT
  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    const maxDuration = Duration(seconds: 2);
    final isBackButtonPressedTwice =
        _lastBackPressed != null &&
        now.difference(_lastBackPressed!) <= maxDuration;

    if (isBackButtonPressedTwice) {
      SystemNavigator.pop();
      return true;
    } else {
      _lastBackPressed = now;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF1A237E),
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0, // Allow pop only on dashboard
      onPopInvoked: (bool didPop) async {
        if (!didPop) {
          if (_selectedIndex != 0) {
            // If not on dashboard, go back to dashboard
            if (mounted) {
              setState(() => _selectedIndex = 0);
            }
          } else {
            // If on dashboard, show exit confirmation
            await _onWillPop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kora Expense Tracker'),
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1A237E)),
              )
            : _getCurrentScreen(),
        floatingActionButton: _selectedIndex == 0
            ? FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTransactionScreen(
                        accounts: _accounts,
                        categories: _categories,
                      ),
                    ),
                  );
                  if (mounted && result == true) {
                    await _loadData();
                  }
                },
                backgroundColor: const Color(0xFF1A237E),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : _selectedIndex == 2
                ? FloatingActionButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddEditAccountScreen(),
                        ),
                      );
                      if (mounted && result == true) {
                        await _loadData();
                        // Don't show duplicate message - AddEditAccountScreen already shows one
                      }
                    },
                    backgroundColor: const Color(0xFF1A237E),
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                : null,
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onNavItemTapped,
          selectedItemColor: const Color(0xFF1A237E),
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: 'Accounts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
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
            'Total Balance',
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
    );
  }

  Widget _buildMonthlySummary() {
    return Row(
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
                      'Income',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '₹${NumberFormat('#,##,###.##').format(_monthlyIncome)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This month',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
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
                    Icon(Icons.trending_down, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Expenses',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '₹${NumberFormat('#,##,###.##').format(_monthlyExpenses)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This month',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // NEW: Credit utilization summary card
  Widget _buildCreditUtilizationSummary() {
    final creditCards = _accounts
        .where((account) => account.subType == AccountSubType.creditCard)
        .toList();

    if (creditCards.isEmpty) return const SizedBox.shrink();

    double totalCreditLimit = 0.0;
    double totalOutstanding = 0.0;
    int highUsageCards = 0;
    int moderateUsageCards = 0;

    for (final card in creditCards) {
      if (card.creditLimit != null && card.outstandingAmount != null) {
        totalCreditLimit += card.creditLimit!;
        totalOutstanding += card.outstandingAmount!;

        final utilization = card.outstandingAmount! / card.creditLimit!;
        if (utilization > 0.6) {
          highUsageCards++;
        } else if (utilization > 0.3) {
          moderateUsageCards++;
        }
      }
    }

    if (totalCreditLimit == 0) return const SizedBox.shrink();

    final overallUtilization = totalOutstanding / totalCreditLimit;
    final utilizationColor = overallUtilization > 0.6
        ? Colors.red[700]!
        : overallUtilization > 0.3
        ? Colors.orange[700]!
        : Colors.green[700]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, color: utilizationColor),
              const SizedBox(width: 8),
              Text(
                'Credit Card Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: utilizationColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(overallUtilization * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: utilizationColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Overall utilization progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Utilization',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    '₹${NumberFormat('#,##,###.##').format(totalOutstanding)} / ₹${NumberFormat('#,##,###.##').format(totalCreditLimit)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: overallUtilization.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation(utilizationColor),
                minHeight: 8,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Usage alerts summary
          Row(
            children: [
              if (highUsageCards > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔴', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '$highUsageCards High Usage',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (moderateUsageCards > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🟡', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '$moderateUsageCards Moderate',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          if (highUsageCards > 0 || moderateUsageCards > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tap to view detailed account information',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    if (mounted) {
                      setState(() => _selectedIndex = 2);
                    }
                  },
                  icon: const Icon(Icons.account_balance_wallet, size: 16),
                  label: const Text('View Accounts'),
                  style: TextButton.styleFrom(
                    foregroundColor: utilizationColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final recentTransactions = _transactions.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            if (_transactions.isNotEmpty)
              TextButton(
                onPressed: () {
                  if (mounted) {
                    setState(() => _selectedIndex = 1);
                  }
                },
                child: const Text(
                  'View All',
                  style: TextStyle(color: Color(0xFF1A237E)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentTransactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first transaction',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          // Fixed transaction list to prevent mouse tracker issues
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentTransactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final transaction = recentTransactions[index];
              return _TransactionTile(
                key: ValueKey('transaction_${transaction.id}'),
                transaction: transaction,
                categories: _categories,
                accounts: _accounts,
                onEdit: _editTransactionFromDashboard,
                onDelete: _deleteTransactionFromDashboard,
              );
            },
          ),
      ],
    );
  }
}

// Separate stateless widget to prevent mouse tracker issues
class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final List<Category> categories;
  final List<Account> accounts;
  final Function(Transaction) onEdit;
  final Function(Transaction) onDelete;

  const _TransactionTile({
    super.key,
    required this.transaction,
    required this.categories,
    required this.accounts,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final category = categories.firstWhere(
      (cat) => cat.id == transaction.categoryId,
      orElse: () =>
          Category(name: 'Unknown', type: CategoryType.expense, icon: '❓'),
    );
    final account = accounts.firstWhere(
      (acc) => acc.id == transaction.accountId,
      orElse: () => Account(
        name: 'Unknown',
        type: AccountType.asset,
        subType: AccountSubType.cash,
        balance: 0,
        currency: 'INR',
      ),
    );

    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onEdit(transaction),
        onLongPress: () => onDelete(transaction),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(category.color.replaceAll('#', '0xFF')),
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    category.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category.name} • ${account.name}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, yyyy').format(transaction.date),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (transaction.type == TransactionType.income
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFD32F2F))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${transaction.type == TransactionType.income ? '+' : '-'}₹${NumberFormat('#,##,###.##').format(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: transaction.type == TransactionType.income
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFD32F2F),
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