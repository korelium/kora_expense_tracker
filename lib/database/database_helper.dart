import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart' as AppTransaction;
import '../models/enums.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'expense_tracker.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        subType TEXT NOT NULL,
        balance REAL NOT NULL,
        creditLimit REAL,
        outstandingAmount REAL,
        currency TEXT NOT NULL,
        isActive INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        parentId INTEGER,
        isActive INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (parentId) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      date INTEGER NOT NULL,
      time INTEGER,
      type TEXT NOT NULL,
      accountId INTEGER NOT NULL,
      categoryId INTEGER NOT NULL,
      notes TEXT,
      createdAt INTEGER NOT NULL,
      updatedAt INTEGER NOT NULL,
      FOREIGN KEY (accountId) REFERENCES accounts (id),
      FOREIGN KEY (categoryId) REFERENCES categories (id)
    )
    ''');

    await _insertDefaultCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN time INTEGER');
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      // Income categories with proper icons
      {'name': 'Salary', 'type': 'income', 'icon': '💰', 'color': '#4CAF50'},
      {'name': 'Business', 'type': 'income', 'icon': '💼', 'color': '#2196F3'},
      {
        'name': 'Investment',
        'type': 'income',
        'icon': '📈',
        'color': '#9C27B0',
      },
      {
        'name': 'Freelancing',
        'type': 'income',
        'icon': '💻',
        'color': '#FF9800',
      },
      {
        'name': 'Other Income',
        'type': 'income',
        'icon': '💵',
        'color': '#607D8B',
      },

      // Expense categories with proper icons
      {
        'name': 'Food & Dining',
        'type': 'expense',
        'icon': '🍽️',
        'color': '#F44336',
      },
      {
        'name': 'Transportation',
        'type': 'expense',
        'icon': '🚗',
        'color': '#FF5722',
      },
      {
        'name': 'Shopping',
        'type': 'expense',
        'icon': '🛍️',
        'color': '#E91E63',
      },
      {
        'name': 'Entertainment',
        'type': 'expense',
        'icon': '🎬',
        'color': '#9C27B0',
      },
      {
        'name': 'Bills & Utilities',
        'type': 'expense',
        'icon': '⚡',
        'color': '#FFC107',
      },
      {
        'name': 'Healthcare',
        'type': 'expense',
        'icon': '🏥',
        'color': '#00BCD4',
      },
      {
        'name': 'Education',
        'type': 'expense',
        'icon': '📚',
        'color': '#3F51B5',
      },
      {
        'name': 'Groceries',
        'type': 'expense',
        'icon': '🛒',
        'color': '#4CAF50',
      },
      {
        'name': 'Balance Adjustment',
        'type': 'expense',
        'icon': '⚖️',
        'color': '#795548',
      },
    ];

    for (var category in defaultCategories) {
      await db.insert('categories', {
        'name': category['name'],
        'description': null,
        'type': category['type'],
        'icon': category['icon'],
        'color': category['color'],
        'parentId': null,
        'isActive': 1,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // ENHANCED: Balance calculation with credit card support
  Future<void> updateAccountBalance(int accountId) async {
    final db = await database;

    final incomeResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as totalIncome FROM transactions WHERE accountId = ? AND type = ?',
      [accountId, 'income'],
    );
    final totalIncome = (incomeResult.first['totalIncome'] as num).toDouble();

    final expenseResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as totalExpense FROM transactions WHERE accountId = ? AND type = ?',
      [accountId, 'expense'],
    );
    final totalExpense = (expenseResult.first['totalExpense'] as num)
        .toDouble();

    final newBalance = totalIncome - totalExpense;

    await db.update(
      'accounts',
      {
        'balance': newBalance,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  // ENHANCED: Smart account update with user confirmation for balance adjustment
  Future<void> updateAccount(
    Account account, {
    bool adjustBalance = false,
  }) async {
    final db = await database;

    final currentResult = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [account.id],
    );
    if (currentResult.isEmpty) return;

    final currentAccount = Account.fromMap(currentResult.first);
    final balanceDifference = account.balance - currentAccount.balance;

    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );

    // Only create adjustment transaction if user confirmed and balance changed
    if (adjustBalance && balanceDifference != 0) {
      final categories = await getCategories();
      final adjustmentCategory = categories.firstWhere(
        (cat) => cat.name == 'Balance Adjustment',
        orElse: () => categories.first,
      );

      final adjustmentTransaction = AppTransaction.Transaction(
        title: 'Balance Adjustment',
        amount: balanceDifference.abs(),
        date: DateTime.now(),
        time: DateTime.now(),
        type: balanceDifference > 0
            ? TransactionType.income
            : TransactionType.expense,
        accountId: account.id!,
        categoryId: adjustmentCategory.id!,
        notes: 'Manual balance adjustment',
      );

      await db.insert('transactions', adjustmentTransaction.toMap());
      await updateAccountBalance(account.id!);
    }
  }

  // Account operations
  Future<int> insertAccount(Account account) async {
    final db = await database;
    final id = await db.insert('accounts', account.toMap());

    if (account.balance > 0) {
      final categories = await getCategories();
      final incomeCategory = categories.firstWhere(
        (cat) => cat.type == CategoryType.income,
        orElse: () => categories.first,
      );

      final initialTransaction = AppTransaction.Transaction(
        title: 'Initial Balance',
        amount: account.balance,
        date: DateTime.now(),
        time: DateTime.now(),
        type: TransactionType.income,
        accountId: id,
        categoryId: incomeCategory.id!,
        notes: 'Initial account balance',
      );

      await db.insert('transactions', initialTransaction.toMap());
      await updateAccountBalance(id);
    }

    return id;
  }

  Future<List<Account>> getAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'isActive = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Account.fromMap(maps[i]));
  }

  Future<void> deleteAccount(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'accountId = ?', whereArgs: [id]);
    await db.update(
      'accounts',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Category operations
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'isActive = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'categoryId = ?', whereArgs: [id]);
    await db.update(
      'categories',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Transaction operations with time support
  Future<int> insertTransaction(AppTransaction.Transaction transaction) async {
    final db = await database;
    final id = await db.insert('transactions', transaction.toMap());
    await updateAccountBalance(transaction.accountId);
    return id;
  }

  Future<List<AppTransaction.Transaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC, time DESC',
    );
    return List.generate(
      maps.length,
      (i) => AppTransaction.Transaction.fromMap(maps[i]),
    );
  }

  Future<void> updateTransaction(AppTransaction.Transaction transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    await updateAccountBalance(transaction.accountId);
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    final transactionResult = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (transactionResult.isNotEmpty) {
      final accountId = transactionResult.first['accountId'] as int;
      await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
      await updateAccountBalance(accountId);
    }
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
