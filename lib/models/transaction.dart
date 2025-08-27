import 'enums.dart';

class Transaction {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final DateTime time; // NEW: Added time field
  final TransactionType type;
  final int accountId;
  final int categoryId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    DateTime? time, // NEW: Time parameter
    required this.type,
    required this.accountId,
    required this.categoryId,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : time = time ?? DateTime.now(), // Default to now if not provided
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'time': time.millisecondsSinceEpoch, // NEW: Include time
      'type': type.toString().split('.').last,
      'accountId': accountId,
      'categoryId': categoryId,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'].toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      time: DateTime.fromMillisecondsSinceEpoch(map['time'] ?? map['date']), // NEW: Handle time
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      accountId: map['accountId'],
      categoryId: map['categoryId'],
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  Transaction copyWith({
    String? title,
    double? amount,
    DateTime? date,
    DateTime? time,
    TransactionType? type,
    int? accountId,
    int? categoryId,
    String? notes,
    bool updateTimestamp = true,
  }) {
    return Transaction(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updateTimestamp ? DateTime.now() : updatedAt,
    );
  }

  @override
  String toString() {
    return 'Transaction{id: $id, title: $title, amount: $amount, date: $date, time: $time, type: $type}';
  }
}
