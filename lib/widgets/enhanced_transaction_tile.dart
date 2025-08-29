import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/enums.dart';

// Enhanced transaction tile with beautiful design
class EnhancedTransactionTile extends StatelessWidget {
  final Transaction transaction;
  final List<Category> categories;
  final List<Account> accounts;
  final Function(Transaction) onEdit;
  final Function(Transaction) onDelete;
  final bool isCompact;

  const EnhancedTransactionTile({
    super.key,
    required this.transaction,
    required this.categories,
    required this.accounts,
    required this.onEdit,
    required this.onDelete,
    this.isCompact = false,
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

    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    
    Color primaryColor;
    Color backgroundColor;
    IconData typeIcon;
    
    if (isIncome) {
      primaryColor = const Color(0xFF2E7D32);
      backgroundColor = const Color(0xFF2E7D32).withOpacity(0.08);
      typeIcon = Icons.trending_up;
    } else if (isTransfer) {
      primaryColor = const Color(0xFF1565C0);
      backgroundColor = const Color(0xFF1565C0).withOpacity(0.08);
      typeIcon = Icons.swap_horiz;
    } else {
      primaryColor = const Color(0xFFD32F2F);
      backgroundColor = const Color(0xFFD32F2F).withOpacity(0.08);
      typeIcon = Icons.trending_down;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            backgroundColor,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.12),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: primaryColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onEdit(transaction),
          onLongPress: () => onDelete(transaction),
          splashColor: primaryColor.withOpacity(0.1),
          highlightColor: primaryColor.withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            child: Row(
              children: [
                // Category Icon with enhanced styling
                Container(
                  width: isCompact ? 48 : 56,
                  height: isCompact ? 48 : 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(int.parse(category.color.replaceAll('#', '0xFF'))),
                        Color(int.parse(category.color.replaceAll('#', '0xFF'))).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(int.parse(category.color.replaceAll('#', '0xFF'))).withOpacity(0.3),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      category.icon,
                      style: TextStyle(
                        fontSize: isCompact ? 20 : 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Transaction Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with better typography
                      Text(
                        transaction.title,
                        style: TextStyle(
                          fontSize: isCompact ? 16 : 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isCompact ? 4 : 6),
                      
                      // Category and Account info with icons
                      Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _getAccountIcon(account.subType),
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              account.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Date with calendar icon
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCompact 
                                ? DateFormat('MMM dd, yyyy').format(transaction.date)
                                : DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.time),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Amount with enhanced styling
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Transaction type indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            typeIcon,
                            size: 14,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isIncome ? 'Income' : isTransfer ? 'Transfer' : 'Expense',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Amount
                    Text(
                      '${isIncome ? '+' : isTransfer ? '' : '-'}₹${NumberFormat('#,##,###').format(transaction.amount)}',
                      style: TextStyle(
                        fontSize: isCompact ? 16 : 18,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAccountIcon(AccountSubType subType) {
    switch (subType) {
      case AccountSubType.bank:
        return Icons.account_balance;
      case AccountSubType.cash:
        return Icons.payments;
      case AccountSubType.digitalWallet:
        return Icons.account_balance_wallet;
      case AccountSubType.creditCard:
        return Icons.credit_card;
      case AccountSubType.loan:
        return Icons.receipt_long;
      default:
        return Icons.account_balance_wallet;
    }
  }
}