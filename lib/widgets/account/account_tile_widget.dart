import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/account.dart';
import '../../models/enums.dart';
import '../../utils/formatters/credit_card_formatters.dart';

class AccountTileWidget extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const AccountTileWidget({
    super.key,
    required this.account,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
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
        subtitle: _buildSubtitle(),
        trailing: _buildTrailing(context), // UPDATED: Pass context
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),

        // ACCOUNT TYPE + UTILIZATION DOT
        Row(
          children: [
            Expanded(
              child: Text(
                _getAccountSubtypeLabel(account.subType),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (account.subType == AccountSubType.creditCard &&
                account.creditLimit != null &&
                account.outstandingAmount != null) ...[
              const SizedBox(width: 8),
              _getUtilizationDot(
                account.outstandingAmount! / account.creditLimit!,
              ),
            ],
          ],
        ),

        // CREDIT CARD SPECIFIC INFORMATION
        if (account.subType == AccountSubType.creditCard) ...[
          // CREDIT LIMIT
          if (account.creditLimit != null)
            Text(
              'Credit Limit: ₹${NumberFormat('#,##,###.##').format(account.creditLimit)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              overflow: TextOverflow.ellipsis,
            ),

          // UTILIZATION PERCENTAGE + HEALTH STATUS
          if (account.outstandingAmount != null &&
              account.creditLimit != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Utilization: ${((account.outstandingAmount! / account.creditLimit!) * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: CreditCardFormatters.getUtilizationHealthColor(
                        account.outstandingAmount! / account.creditLimit!,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: CreditCardFormatters.getUtilizationHealthColor(
                      account.outstandingAmount! / account.creditLimit!,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: CreditCardFormatters.getUtilizationHealthColor(
                        account.outstandingAmount! / account.creditLimit!,
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    CreditCardFormatters.getUtilizationHealthStatus(
                      account.outstandingAmount! / account.creditLimit!,
                    ),
                    style: TextStyle(
                      fontSize: 9,
                      color: CreditCardFormatters.getUtilizationHealthColor(
                        account.outstandingAmount! / account.creditLimit!,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // HEALTHY LIMIT INDICATOR (30%) - Improved layout
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.health_and_safety,
                      size: 12,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Healthy limit: ${CreditCardFormatters.formatHealthyLimit(account.creditLimit!)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            // UTILIZATION PROGRESS BAR
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (account.outstandingAmount! / account.creditLimit!)
                    .clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: CreditCardFormatters.getUtilizationColor(
                      account.outstandingAmount! / account.creditLimit!,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 6),

          // BANK NAME AND CARD TYPE
          if (account.creditCardDetails?.bankName != null)
            Text(
              '${account.creditCardDetails!.bankName} • ${account.creditCardDetails!.cardType}',
              style: TextStyle(fontSize: 11, color: Colors.blue[600]),
              overflow: TextOverflow.ellipsis,
            ),

          // FEATURE: Bill cycle information - Improved layout
          Row(
            children: [
              // Left side - Bill and Due dates closer together
              Flexible(
                flex: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (account.creditCardDetails?.billingDate != null) ...[
                      Icon(
                        Icons.calendar_today,
                        size: 11,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Bill: ${account.creditCardDetails!.billingDate}th',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    if (account.creditCardDetails?.billingDate != null &&
                        account.creditCardDetails?.dueDate != null) ...[
                      const SizedBox(width: 6), // Reduced gap
                      Icon(Icons.payment, size: 11, color: Colors.red[600]),
                      const SizedBox(width: 2),
                      Text(
                        'Due: ${account.creditCardDetails!.dueDate}th',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Right side - Bill countdown
              if (account.creditCardDetails?.billingDate != null) ...[
                Flexible(
                  flex: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.schedule, size: 11, color: Colors.orange[600]),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          'Bill in ${CreditCardFormatters.getDaysUntilBill(account.creditCardDetails!.billingDate!)} days',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.orange[600],
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ]
        // NON-CREDIT CARD ACCOUNTS
        else if (account.type == AccountType.liability &&
            account.creditLimit != null)
          Text(
            'Credit Limit: ₹${NumberFormat('#,##,###.##').format(account.creditLimit)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  // UPDATED: _buildTrailing without Pay Button
  Widget _buildTrailing(BuildContext context) {
    return account.subType == AccountSubType.creditCard
        ? Text(
            CreditCardFormatters.formatCreditCardBalance(
              account.outstandingAmount ?? 0,
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: (account.outstandingAmount ?? 0) > 0
                  ? Colors.red[700]
                  : Colors.green[700],
            ),
            overflow: TextOverflow.ellipsis,
          )
        : Text(
            '₹${NumberFormat('#,##0').format(account.balance)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: account.balance < 0 ? Colors.red[700] : Colors.green[700],
            ),
            overflow: TextOverflow.ellipsis,
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

  Widget _getUtilizationDot(double utilization) {
    if (utilization <= 0.3) {
      return const Text('🟢', style: TextStyle(fontSize: 16));
    } else if (utilization <= 0.6) {
      return const Text('🟡', style: TextStyle(fontSize: 16));
    } else {
      return const Text('🔴', style: TextStyle(fontSize: 16));
    }
  }
}
