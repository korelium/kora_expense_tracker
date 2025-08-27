import 'enums.dart';

class Account {
  final int? id;
  final String name;
  final AccountType type;
  final AccountSubType subType;
  final double balance;
  final double? creditLimit; // For credit cards
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

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
    };
  }

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
    );
  }

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
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Account{id: $id, name: $name, type: $type, balance: $balance}';
  }
}
