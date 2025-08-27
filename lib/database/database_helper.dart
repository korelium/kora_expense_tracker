import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart'
    as AppTransaction; // ALIAS TO AVOID CONFLICT

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
    return await openDatabase(path, version: 1, onCreate: _createTables);
  }

  Future<void> _createTables(Database db, int version) async {
    // Create accounts table
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

    // Create categories table
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

    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
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

    // Insert default categories
    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      // Income categories
      {'name': 'Salary', 'type': 'income', 'icon': '💰', 'color': '#4CAF50'},
      {'name': 'Business', 'type': 'income', 'icon': '💼', 'color': '#2196F3'},
      {
        'name': 'Investment',
        'type': 'income',
        'icon': '📈',
        'color': '#9C27B0',
      },
      {
        'name': 'Other Income',
        'type': 'income',
        'icon': '💵',
        'color': '#FF9800',
      },

      // Expense categories
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
        'color': '#03DAC6',
      },
      {
        'name': 'Education',
        'type': 'expense',
        'icon': '📚',
        'color': '#3F51B5',
      },
      {'name': 'Other', 'type': 'expense', 'icon': '📂', 'color': '#607D8B'},
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

  // Account operations
  Future<int> insertAccount(Account account) async {
    final db = await database;
    return await db.insert('accounts', account.toMap());
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

  Future<void> updateAccount(Account account) async {
    final db = await database;
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> deleteAccount(int id) async {
    final db = await database;
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
    await db.update(
      'categories',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Transaction operations - USING ALIAS
  Future<int> insertTransaction(AppTransaction.Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<AppTransaction.Transaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
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
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
