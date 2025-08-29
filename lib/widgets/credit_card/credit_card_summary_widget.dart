import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/account.dart';
import '../../models/enums.dart';

class CreditCardSummaryWidget extends StatelessWidget {
  final List<Account> accounts;

  const CreditCardSummaryWidget({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    final creditCards = accounts
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
        gradient: LinearGradient(
          colors: [
            utilizationColor.withOpacity(0.1),
            utilizationColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: utilizationColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.credit_card, color: utilizationColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Credit Card Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: utilizationColor,
                      ),
                    ),
                    Text(
                      '${creditCards.length} active card${creditCards.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: utilizationColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: utilizationColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(overallUtilization * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: utilizationColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mobile-optimized stats grid
          Column(
            children: [
              // First row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Credit Limit',
                      '₹${NumberFormat('#,##,###').format(totalCreditLimit)}',
                      Colors.blue[700]!,
                      Icons.credit_card,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Outstanding',
                      '₹${NumberFormat('#,##,###').format(totalOutstanding)}',
                      Colors.red[700]!,
                      Icons.account_balance,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Second row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Available',
                      '₹${NumberFormat('#,##,###').format(totalCreditLimit - totalOutstanding)}',
                      Colors.green[700]!,
                      Icons.account_balance_wallet,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Healthy (30%)',
                      '₹${NumberFormat('#,##,###').format(totalCreditLimit * 0.30)}',
                      Colors.green[600]!,
                      Icons.health_and_safety,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Usage alerts
          if (highUsageCards > 0 || moderateUsageCards > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: utilizationColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: utilizationColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    highUsageCards > 0 ? Icons.warning : Icons.info,
                    color: utilizationColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      highUsageCards > 0
                          ? '$highUsageCards card${highUsageCards > 1 ? 's' : ''} with high utilization (>60%)'
                          : '$moderateUsageCards card${moderateUsageCards > 1 ? 's' : ''} with moderate utilization (30-60%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: utilizationColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: overallUtilization <= 0.30
                          ? Colors.green[100]
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: overallUtilization <= 0.30
                            ? Colors.green[300]!
                            : Colors.orange[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.health_and_safety,
                          size: 14,
                          color: overallUtilization <= 0.30
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          overallUtilization <= 0.30 ? 'HEALTHY' : 'MONITOR',
                          style: TextStyle(
                            fontSize: 10,
                            color: overallUtilization <= 0.30
                                ? Colors.green[700]
                                : Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
