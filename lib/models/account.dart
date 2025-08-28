import 'enums.dart';
import 'dart:convert';

// Credit Card Details Class
class CreditCardDetails {
  final String? last6Digits; // Optional for security
  final String? bankName; // HDFC Bank, ICICI, etc.
  final String? cardType; // Visa, MasterCard, etc.
  final String? cardCategory; // Rewards, Cashback, Travel
  final String? cardStatus; // Active, Inactive, Blocked
  final String? expiryDate; // MM/YY format
  final int? billingDate; // Day of month (1-31)
  final int? dueDate; // Day of month (1-31)
  final double? minPaymentAmount; // Current month minimum due
  final String? rewardRate; // "2 pts/₹100" or "5% cashback"
  final double? annualFee; // Annual fee amount
  final double? foreignTransactionFee; // Percentage

  CreditCardDetails({
    this.last6Digits,
    this.bankName,
    this.cardType,
    this.cardCategory,
    this.cardStatus = 'Active',
    this.expiryDate,
    this.billingDate,
    this.dueDate,
    this.minPaymentAmount,
    this.rewardRate,
    this.annualFee,
    this.foreignTransactionFee,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'last6Digits': last6Digits,
      'bankName': bankName,
      'cardType': cardType,
      'cardCategory': cardCategory,
      'cardStatus': cardStatus,
      'expiryDate': expiryDate,
      'billingDate': billingDate,
      'dueDate': dueDate,
      'minPaymentAmount': minPaymentAmount,
      'rewardRate': rewardRate,
      'annualFee': annualFee,
      'foreignTransactionFee': foreignTransactionFee,
    };
  }

  // Create from JSON
  factory CreditCardDetails.fromJson(Map<String, dynamic> json) {
    return CreditCardDetails(
      last6Digits: json['last6Digits'],
      bankName: json['bankName'],
      cardType: json['cardType'],
      cardCategory: json['cardCategory'],
      cardStatus: json['cardStatus'] ?? 'Active',
      expiryDate: json['expiryDate'],
      billingDate: json['billingDate'],
      dueDate: json['dueDate'],
      minPaymentAmount: json['minPaymentAmount']?.toDouble(),
      rewardRate: json['rewardRate'],
      annualFee: json['annualFee']?.toDouble(),
      foreignTransactionFee: json['foreignTransactionFee']?.toDouble(),
    );
  }

  // Helper methods for calculations
  double get utilizationPercentage {
    // This will be calculated from account balance and credit limit
    return 0.0; // Placeholder
  }

  double get availableCredit {
    // This will be calculated from credit limit - current balance
    return 0.0; // Placeholder
  }
}

class Account {
  final int? id;
  final String name;
  final AccountType type;
  final AccountSubType subType;
  final double balance;
  final double? creditLimit; // For credit cards
  final CreditCardDetails? creditCardDetails; // NEW: Credit card specific data
  final double? outstandingAmount; // For credit cards/loans
  final String currency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account({
    this.id,
    required this.name,
    required this.type,
    required this.subType,
    required this.balance,
    this.creditLimit,
    this.outstandingAmount,
    required this.currency,
    this.isActive = true,
    this.creditCardDetails, // NEW: Add this line
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert Account to Map for database operations
  // Convert Account to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'subType': subType.toString().split('.').last,
      'balance': balance,
      'creditLimit': creditLimit,
      'outstandingAmount': outstandingAmount,
      'currency': currency,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'cardDetails': creditCardDetails?.toJson() != null
          ? jsonEncode(creditCardDetails!.toJson())
          : null, // NEW: Add this line
    };
  }

  // Create Account from Map (from database)
  // Create Account from Map (from database)
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      type: AccountType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      subType: AccountSubType.values.firstWhere(
        (e) => e.toString().split('.').last == map['subType'],
      ),
      balance: map['balance'].toDouble(),
      creditLimit: map['creditLimit']?.toDouble(),
      outstandingAmount: map['outstandingAmount']?.toDouble(),
      currency: map['currency'],
      isActive: map['isActive'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      creditCardDetails: map['cardDetails'] != null
          ? CreditCardDetails.fromJson(jsonDecode(map['cardDetails']))
          : null, // NEW: Add this line
    );
  }

  // Create a copy with updated values
  // Create a copy with updated values
  Account copyWith({
    String? name,
    AccountType? type,
    AccountSubType? subType,
    double? balance,
    double? creditLimit,
    double? outstandingAmount,
    String? currency,
    bool? isActive,
    CreditCardDetails? creditCardDetails, // NEW: Add this line
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      subType: subType ?? this.subType,
      balance: balance ?? this.balance,
      creditLimit: creditLimit ?? this.creditLimit,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      creditCardDetails:
          creditCardDetails ?? this.creditCardDetails, // NEW: Add this line
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Account{id: $id, name: $name, type: $type, balance: $balance}';
  }
}
