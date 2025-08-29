import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/enums.dart';

// Separate stateless widget for transaction tiles to prevent mouse tracker issues
class TransactionTileWidget extends StatelessWidget {
  final Transaction transaction;
  final List<Category> categories;
  final List<Account> accounts;
  final Function(Transaction) onEdit;
  final Function(Transaction) onDelete;

  const TransactionTileWidget({
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 2,
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
      ),
    );
  }
}