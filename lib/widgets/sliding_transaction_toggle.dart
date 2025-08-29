import 'package:flutter/material.dart';
import '../models/enums.dart';

class SlidingTransactionToggle extends StatelessWidget {
  final TransactionType selectedType;
  final Function(TransactionType) onTypeChanged;

  const SlidingTransactionToggle({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Sliding background indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: selectedType == TransactionType.income
                ? 4
                : selectedType == TransactionType.expense
                    ? (MediaQuery.of(context).size.width - 40) / 3 + 4
                    : ((MediaQuery.of(context).size.width - 40) / 3) * 2 + 4,
            top: 4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: (MediaQuery.of(context).size.width - 40) / 3 - 8,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: selectedType == TransactionType.income
                      ? [const Color(0xFF2E7D32), const Color(0xFF4CAF50)]
                      : selectedType == TransactionType.expense
                          ? [const Color(0xFFD32F2F), const Color(0xFFEF5350)]
                          : [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: (selectedType == TransactionType.income
                            ? const Color(0xFF2E7D32)
                            : selectedType == TransactionType.expense
                                ? const Color(0xFFD32F2F)
                                : const Color(0xFF1565C0))
                        .withOpacity(0.4),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          // Toggle options
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onTypeChanged(TransactionType.income),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          color: selectedType == TransactionType.income
                              ? Colors.white
                              : const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                Icons.trending_up,
                                color: selectedType == TransactionType.income
                                    ? Colors.white
                                    : const Color(0xFF2E7D32),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('Income'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onTypeChanged(TransactionType.expense),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          color: selectedType == TransactionType.expense
                              ? Colors.white
                              : const Color(0xFFD32F2F),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                Icons.trending_down,
                                color: selectedType == TransactionType.expense
                                    ? Colors.white
                                    : const Color(0xFFD32F2F),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('Expense'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onTypeChanged(TransactionType.transfer),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          color: selectedType == TransactionType.transfer
                              ? Colors.white
                              : const Color(0xFF1565C0),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                Icons.swap_horiz,
                                color: selectedType == TransactionType.transfer
                                    ? Colors.white
                                    : const Color(0xFF1565C0),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('Transfer'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}