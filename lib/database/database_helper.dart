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
      version: 4,
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
      updatedAt INTEGER NOT NULL,
      cardDetails TEXT
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

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN time INTEGER');
    }
    if (oldVersion < 4) {
      // Add credit card details field for enhanced card management
      await db.execute('ALTER TABLE accounts ADD COLUMN cardDetails TEXT');
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

  // PUBLIC: Recreate default categories (for sample data service)
  // Future<void> recreateDefaultCategories() async {
  //   final db = await database;
  //   await _insertDefaultCategories(db);
  // }

  // FIXED: Proper balance calculation without double-counting
  Future updateAccountBalance(int accountId) async {
    final db = await database;

    // Get account details first
    final accountResult = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [accountId],
    );
    if (accountResult.isEmpty) return;

    final account = Account.fromMap(accountResult.first);

    // Get transaction totals
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

    if (account.subType == AccountSubType.creditCard) {
      // CREDIT CARD LOGIC: Outstanding = Total Expenses - Total Payments
      print('🔍 CREDIT CARD BALANCE UPDATE for account $accountId');
      print('💸 Total expenses from transactions: $totalExpense');
      print('💰 Total payments from transactions: $totalIncome');

      // Simple approach: Outstanding = All expenses - All payments
      final newOutstanding = totalExpense - totalIncome;

      print('🧮 Calculation: $totalExpense - $totalIncome = $newOutstanding');

      await db.update(
        'accounts',
        {
          'balance': 0.0,
          'outstandingAmount': newOutstanding,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [accountId],
      );

      print('✅ Credit card outstanding updated to: $newOutstanding');
    } else {
      // Regular accounts: balance = income - expenses
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

  // FIXED: Proper account insertion without double-counting
  Future<int> insertAccount(Account account) async {
    print('🔍 DatabaseHelper.insertAccount called for: ${account.name}');
    try {
      final db = await database;
      final accountMap = account.toMap();
      print('📄 Account map: $accountMap');

      final id = await db.insert('accounts', accountMap);
      print('✅ Account inserted successfully with id: $id');

      // Create initial transaction timestamp slightly in the past to ensure proper ordering
      final initialTransactionTime = DateTime.now().subtract(
        const Duration(seconds: 1),
      );

      if (account.subType == AccountSubType.creditCard) {
        // Credit cards: Create initial transaction for outstanding amount if any
        final initialOutstanding = account.outstandingAmount ?? 0.0;
        print('💳 Credit card created with outstanding: $initialOutstanding');

        if (initialOutstanding > 0) {
          // Create an initial expense transaction to represent the outstanding amount
          final categories = await getCategories();
          final expenseCategory = categories.firstWhere(
            (cat) => cat.type == CategoryType.expense,
            orElse: () => categories.first,
          );

          final initialTransaction = AppTransaction.Transaction(
            title: 'Initial Outstanding',
            amount: initialOutstanding,
            date: initialTransactionTime,
            time: initialTransactionTime,
            type: TransactionType.expense,
            accountId: id,
            categoryId: expenseCategory.id!,
            notes: 'Initial credit card outstanding amount',
          );

          await db.insert('transactions', initialTransaction.toMap());
          print(
            '💳 Initial outstanding transaction created: ₹$initialOutstanding',
          );
        }
      } else if (account.balance != 0) {
        // Regular accounts: create initial balance transaction only if balance is non-zero
        print('💰 Creating initial balance transaction for regular account...');
        final categories = await getCategories();
        final category = categories.firstWhere(
          (cat) =>
              cat.type ==
              (account.balance > 0
                  ? CategoryType.income
                  : CategoryType.expense),
          orElse: () => categories.first,
        );

        final initialTransaction = AppTransaction.Transaction(
          title: 'Initial Balance',
          amount: account.balance.abs(),
          date: initialTransactionTime,
          time: initialTransactionTime,
          type: account.balance > 0
              ? TransactionType.income
              : TransactionType.expense,
          accountId: id,
          categoryId: category.id!,
          notes: 'Initial account balance',
        );

        await db.insert('transactions', initialTransaction.toMap());
        print('💳 Initial transaction created');
        // No need to call updateAccountBalance here as the transaction will match the initial balance
      }

      return id;
    } catch (e) {
      print('❌ Error inserting account ${account.name}: $e');
      rethrow;
    }
  }

  Future<List<Account>> getAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'CASE WHEN type = "asset" THEN 1 ELSE 2 END, createdAt ASC',
    );
    return List.generate(maps.length, (i) => Account.fromMap(maps[i]));
  }

  Future<void> deleteAccount(int id) async {
    final db = await database;
    // Delete all transactions for this account
    await db.delete('transactions', where: 'accountId = ?', whereArgs: [id]);
    // Deactivate the account
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
      orderBy: 'date DESC, time DESC, createdAt DESC',
    );
    return List.generate(
      maps.length,
      (i) => AppTransaction.Transaction.fromMap(maps[i]),
    );
  }

  Future<void> updateTransaction(AppTransaction.Transaction transaction) async {
    final db = await database;

    // Get the old transaction to update the old account balance
    final oldTransactionResult = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [transaction.id],
    );

    if (oldTransactionResult.isNotEmpty) {
      final oldTransaction = AppTransaction.Transaction.fromMap(
        oldTransactionResult.first,
      );
      final oldAccountId = oldTransaction.accountId;

      // Update the transaction
      await db.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      // Update both old and new account balances if they're different
      if (oldAccountId != transaction.accountId) {
        await updateAccountBalance(oldAccountId); // Update old account
        await updateAccountBalance(transaction.accountId); // Update new account
      } else {
        await updateAccountBalance(transaction.accountId); // Same account
      }
    }
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

  // PUBLIC: Recreate default categories (for sample data service)
  Future<void> recreateDefaultCategories() async {
    final db = await database;
    await _insertDefaultCategories(db);
  }
}
