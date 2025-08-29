import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/enums.dart';

class DataExportImportService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Export all data to CSV files
  Future<String> exportDataToCSV() async {
    try {
      // Request storage permission
      await _requestStoragePermission();

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Export accounts
      await _exportAccounts('${exportDir.path}/accounts_$timestamp.csv');
      
      // Export categories
      await _exportCategories('${exportDir.path}/categories_$timestamp.csv');
      
      // Export transactions
      await _exportTransactions('${exportDir.path}/transactions_$timestamp.csv');

      // Create a summary file
      final summaryPath = '${exportDir.path}/export_summary_$timestamp.txt';
      await _createExportSummary(summaryPath, timestamp);

      return exportDir.path;
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  // Export accounts to CSV
  Future<void> _exportAccounts(String filePath) async {
    final accounts = await _dbHelper.getAccounts();
    
    final List<List<dynamic>> csvData = [
      // Header
      ['ID', 'Name', 'Type', 'SubType', 'Balance', 'CreditLimit', 'OutstandingAmount', 'Currency', 'CreatedAt', 'UpdatedAt']
    ];

    for (final account in accounts) {
      csvData.add([
        account.id,
        account.name,
        account.type.toString().split('.').last,
        account.subType.toString().split('.').last,
        account.balance,
        account.creditLimit ?? '',
        account.outstandingAmount ?? '',
        account.currency,
        account.createdAt.millisecondsSinceEpoch,
        account.updatedAt.millisecondsSinceEpoch,
      ]);
    }

    final csv = const ListToCsvConverter().convert(csvData);
    final file = File(filePath);
    await file.writeAsString(csv);
  }

  // Export categories to CSV
  Future<void> _exportCategories(String filePath) async {
    final categories = await _dbHelper.getCategories();
    
    final List<List<dynamic>> csvData = [
      // Header
      ['ID', 'Name', 'Description', 'Type', 'Icon', 'Color', 'ParentId', 'CreatedAt', 'UpdatedAt']
    ];

    for (final category in categories) {
      csvData.add([
        category.id,
        category.name,
        category.description ?? '',
        category.type.toString().split('.').last,
        category.icon,
        category.color,
        category.parentId ?? '',
        category.createdAt.millisecondsSinceEpoch,
        category.updatedAt.millisecondsSinceEpoch,
      ]);
    }

    final csv = const ListToCsvConverter().convert(csvData);
    final file = File(filePath);
    await file.writeAsString(csv);
  }

  // Export transactions to CSV
  Future<void> _exportTransactions(String filePath) async {
    final transactions = await _dbHelper.getTransactions();
    
    final List<List<dynamic>> csvData = [
      // Header
      ['ID', 'Title', 'Amount', 'Date', 'Time', 'Type', 'AccountId', 'CategoryId', 'Notes', 'CreatedAt', 'UpdatedAt']
    ];

    for (final transaction in transactions) {
      csvData.add([
        transaction.id,
        transaction.title,
        transaction.amount,
        transaction.date.millisecondsSinceEpoch,
        transaction.time.millisecondsSinceEpoch,
        transaction.type.toString().split('.').last,
        transaction.accountId,
        transaction.categoryId,
        transaction.notes ?? '',
        transaction.createdAt.millisecondsSinceEpoch,
        transaction.updatedAt.millisecondsSinceEpoch,
      ]);
    }

    final csv = const ListToCsvConverter().convert(csvData);
    final file = File(filePath);
    await file.writeAsString(csv);
  }

  // Create export summary
  Future<void> _createExportSummary(String filePath, int timestamp) async {
    final accounts = await _dbHelper.getAccounts();
    final categories = await _dbHelper.getCategories();
    final transactions = await _dbHelper.getTransactions();
    
    final summary = '''
Kora Expense Tracker - Data Export Summary
==========================================

Export Date: ${DateTime.fromMillisecondsSinceEpoch(timestamp)}
Export Timestamp: $timestamp

Data Summary:
- Accounts: ${accounts.length}
- Categories: ${categories.length}
- Transactions: ${transactions.length}

Files Exported:
- accounts_$timestamp.csv
- categories_$timestamp.csv
- transactions_$timestamp.csv

To import this data:
1. Open Kora Expense Tracker
2. Go to Settings > Import Data
3. Select the CSV files from this export

Note: Import will replace existing data. Make sure to backup current data before importing.
''';

    final file = File(filePath);
    await file.writeAsString(summary);
  }

  // Share exported files
  Future<void> shareExportedData(String exportPath) async {
    final files = Directory(exportPath).listSync()
        .where((file) => file.path.endsWith('.csv') || file.path.endsWith('.txt'))
        .map((file) => XFile(file.path))
        .toList();

    if (files.isNotEmpty) {
      await Share.shareXFiles(
        files,
        text: 'Kora Expense Tracker - Exported Data',
        subject: 'My Financial Data Export',
      );
    }
  }

  // Import data from CSV files
  Future<Map<String, int>> importDataFromCSV() async {
    try {
      // Pick CSV files
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No files selected');
      }

      int accountsImported = 0;
      int categoriesImported = 0;
      int transactionsImported = 0;

      for (final file in result.files) {
        if (file.path == null) continue;
        
        final fileName = file.name.toLowerCase();
        final csvContent = await File(file.path!).readAsString();
        final csvData = const CsvToListConverter().convert(csvContent);

        if (fileName.contains('account')) {
          accountsImported += await _importAccounts(csvData);
        } else if (fileName.contains('categor')) {
          categoriesImported += await _importCategories(csvData);
        } else if (fileName.contains('transaction')) {
          transactionsImported += await _importTransactions(csvData);
        }
      }

      return {
        'accounts': accountsImported,
        'categories': categoriesImported,
        'transactions': transactionsImported,
      };
    } catch (e) {
      throw Exception('Import failed: $e');
    }
  }

  // Import accounts from CSV data
  Future<int> _importAccounts(List<List<dynamic>> csvData) async {
    if (csvData.isEmpty) return 0;
    
    int imported = 0;
    // Skip header row
    for (int i = 1; i < csvData.length; i++) {
      try {
        final row = csvData[i];
        if (row.length < 8) continue;

        final account = Account(
          name: row[1].toString(),
          type: _parseAccountType(row[2].toString()),
          subType: _parseAccountSubType(row[3].toString()),
          balance: double.tryParse(row[4].toString()) ?? 0.0,
          creditLimit: row[5].toString().isEmpty ? null : double.tryParse(row[5].toString()),
          outstandingAmount: row[6].toString().isEmpty ? null : double.tryParse(row[6].toString()),
          currency: row[7].toString(),
        );

        await _dbHelper.insertAccount(account);
        imported++;
      } catch (e) {
        print('Error importing account row $i: $e');
      }
    }
    return imported;
  }

  // Import categories from CSV data
  Future<int> _importCategories(List<List<dynamic>> csvData) async {
    if (csvData.isEmpty) return 0;
    
    int imported = 0;
    // Skip header row
    for (int i = 1; i < csvData.length; i++) {
      try {
        final row = csvData[i];
        if (row.length < 6) continue;

        final category = Category(
          name: row[1].toString(),
          description: row[2].toString().isEmpty ? null : row[2].toString(),
          type: _parseCategoryType(row[3].toString()),
          icon: row[4].toString(),
          color: row[5].toString(),
          parentId: row[6].toString().isEmpty ? null : int.tryParse(row[6].toString()),
        );

        await _dbHelper.insertCategory(category);
        imported++;
      } catch (e) {
        print('Error importing category row $i: $e');
      }
    }
    return imported;
  }

  // Import transactions from CSV data
  Future<int> _importTransactions(List<List<dynamic>> csvData) async {
    if (csvData.isEmpty) return 0;
    
    int imported = 0;
    // Skip header row
    for (int i = 1; i < csvData.length; i++) {
      try {
        final row = csvData[i];
        if (row.length < 8) continue;

        final transaction = Transaction(
          title: row[1].toString(),
          amount: double.tryParse(row[2].toString()) ?? 0.0,
          date: DateTime.fromMillisecondsSinceEpoch(int.tryParse(row[3].toString()) ?? DateTime.now().millisecondsSinceEpoch),
          time: DateTime.fromMillisecondsSinceEpoch(int.tryParse(row[4].toString()) ?? DateTime.now().millisecondsSinceEpoch),
          type: _parseTransactionType(row[5].toString()),
          accountId: int.tryParse(row[6].toString()) ?? 1,
          categoryId: int.tryParse(row[7].toString()) ?? 1,
          notes: row[8].toString().isEmpty ? null : row[8].toString(),
        );

        await _dbHelper.insertTransaction(transaction);
        imported++;
      } catch (e) {
        print('Error importing transaction row $i: $e');
      }
    }
    return imported;
  }

  // Helper methods to parse enums
  AccountType _parseAccountType(String value) {
    switch (value.toLowerCase()) {
      case 'asset':
        return AccountType.asset;
      case 'liability':
        return AccountType.liability;
      default:
        return AccountType.asset;
    }
  }

  AccountSubType _parseAccountSubType(String value) {
    switch (value.toLowerCase()) {
      case 'bank':
        return AccountSubType.bank;
      case 'cash':
        return AccountSubType.cash;
      case 'digitalwallet':
        return AccountSubType.digitalWallet;
      case 'creditcard':
        return AccountSubType.creditCard;
      case 'loan':
        return AccountSubType.loan;
      default:
        return AccountSubType.cash;
    }
  }

  CategoryType _parseCategoryType(String value) {
    switch (value.toLowerCase()) {
      case 'income':
        return CategoryType.income;
      case 'expense':
        return CategoryType.expense;
      default:
        return CategoryType.expense;
    }
  }

  TransactionType _parseTransactionType(String value) {
    switch (value.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }

  // Request storage permission
  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission denied');
      }
    }
  }
}