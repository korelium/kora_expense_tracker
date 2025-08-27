import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/enums.dart';
import 'add_transaction_screen.dart';

// TRANSACTIONS LIST SCREEN - View all recorded transactions
class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  List<Category> _categories = [];
  List<Transaction> _filteredTransactions = [];

  bool _isLoading = true;
  String _searchQuery = '';
  TransactionType? _filterType;

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
      final categories = await _dbHelper.getCategories();

      setState(() {
        _transactions = transactions;
        _accounts = accounts;
        _categories = categories;
        _filteredTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _transactions.where((transaction) {
        final matchesSearch =
            transaction.title.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            _getCategoryName(
              transaction.categoryId,
            ).toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesType =
            _filterType == null || transaction.type == _filterType;

        return matchesSearch && matchesType;
      }).toList();
    });
  }

  String _getCategoryName(int categoryId) {
    final category = _categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => Category(name: 'Unknown', type: CategoryType.expense),
    );
    return category.name;
  }

  String _getAccountName(int accountId) {
    final account = _accounts.firstWhere(
      (acc) => acc.id == accountId,
      orElse: () => Account(
        name: 'Unknown',
        type: AccountType.asset,
        subType: AccountSubType.cash,
        balance: 0,
        currency: 'INR',
      ),
    );
    return account.name;
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
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
        _loadData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(
                    accounts: _accounts,
                    categories: _categories,
                  ),
                ),
              ).then((_) => _loadData());
            },
            icon: const Icon(Icons.add),
            tooltip: 'Add Transaction',
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // SEARCH AND FILTER BAR
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Column(
                    children: [
                      // SEARCH BAR
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search transactions...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _searchQuery = value;
                          _applyFilters();
                        },
                      ),

                      const SizedBox(height: 12),

                      // FILTER CHIPS
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _filterType == null,
                            onSelected: (selected) {
                              setState(() => _filterType = null);
                              _applyFilters();
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Income'),
                            selected: _filterType == TransactionType.income,
                            selectedColor: Colors.green[100],
                            onSelected: (selected) {
                              setState(
                                () => _filterType = selected
                                    ? TransactionType.income
                                    : null,
                              );
                              _applyFilters();
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Expense'),
                            selected: _filterType == TransactionType.expense,
                            selectedColor: Colors.red[100],
                            onSelected: (selected) {
                              setState(
                                () => _filterType = selected
                                    ? TransactionType.expense
                                    : null,
                              );
                              _applyFilters();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // TRANSACTIONS LIST
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredTransactions.length,
                            itemBuilder: (context, index) {
                              return _buildTransactionTile(
                                _filteredTransactions[index],
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(
                accounts: _accounts,
                categories: _categories,
              ),
            ),
          ).then((_) => _loadData());
        },
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _filterType != null
                ? 'Try adjusting your search or filters'
                : 'Add your first transaction to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final category = _categories.firstWhere(
      (cat) => cat.id == transaction.categoryId,
      orElse: () =>
          Category(name: 'Unknown', type: CategoryType.expense, icon: '❓'),
    );

    final account = _accounts.firstWhere(
      (acc) => acc.id == transaction.accountId,
      orElse: () => Account(
        name: 'Unknown',
        type: AccountType.asset,
        subType: AccountSubType.cash,
        balance: 0,
        currency: 'INR',
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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

        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(
              int.parse(category.color.replaceAll('#', '0xFF')),
            ).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(category.icon, style: const TextStyle(fontSize: 20)),
          ),
        ),

        title: Text(
          transaction.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${category.name} • ${account.name}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('MMM dd, yyyy • h:mm a').format(transaction.date),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                transaction.notes!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),

        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${transaction.type == TransactionType.income ? '+' : '-'}₹${NumberFormat('#,##,###.##').format(transaction.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: transaction.type == TransactionType.income
                    ? Colors.green[700]
                    : Colors.red[700],
              ),
            ),
            const SizedBox(height: 2),
            Icon(
              transaction.type == TransactionType.income
                  ? Icons.trending_up
                  : Icons.trending_down,
              size: 16,
              color: transaction.type == TransactionType.income
                  ? Colors.green[700]
                  : Colors.red[700],
            ),
          ],
        ),

        onLongPress: () => _deleteTransaction(transaction),
      ),
    );
  }
}
