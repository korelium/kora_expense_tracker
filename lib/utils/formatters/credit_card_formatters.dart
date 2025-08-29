import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreditCardFormatters {
  static String formatCreditCardBalance(double outstandingAmount) {
    if (outstandingAmount == 0) {
      return '₹0';
    } else if (outstandingAmount > 0) {
      return '-₹${NumberFormat('#,###').format(outstandingAmount)}';
    } else {
      return '₹${NumberFormat('#,###').format(outstandingAmount.abs())}';
    }
  }

  static String getUtilizationStatus(double utilization) {
    if (utilization <= 0.3) return 'LOW';
    if (utilization <= 0.6) return 'MODERATE';
    return 'HIGH';
  }

  static Color getUtilizationColor(double utilization) {
    if (utilization <= 0.3) return Colors.green[700]!;
    if (utilization <= 0.6) return Colors.orange[700]!;
    return Colors.red[700]!;
  }

  static double get healthyUtilizationThreshold => 0.30;

  static String getUtilizationHealthStatus(double utilization) {
    if (utilization <= 0.30) return 'HEALTHY';
    if (utilization <= 0.60) return 'MODERATE';
    return 'HIGH';
  }

  static Color getUtilizationHealthColor(double utilization) {
    if (utilization <= 0.30) return Colors.green[700]!;
    if (utilization <= 0.60) return Colors.orange[700]!;
    return Colors.red[700]!;
  }

  static String formatHealthyLimit(double creditLimit) {
    final healthyLimit = creditLimit * healthyUtilizationThreshold;
    return '₹${NumberFormat('#,##,###').format(healthyLimit)}';
  }

  // FEATURE: Calculate days until next bill
  static int getDaysUntilBill(int billingDate) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, billingDate);
    final nextMonth = DateTime(now.year, now.month + 1, billingDate);

    final targetDate = now.isBefore(currentMonth) ? currentMonth : nextMonth;
    return targetDate.difference(now).inDays;
  }
}
