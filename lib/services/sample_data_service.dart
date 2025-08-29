import '../database/database_helper.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/enums.dart';

class SampleDataService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // FEATURE: Create realistic Indian sample data
  Future<void> loadSampleData() async {
    print('📊 Creating sample accounts...');
    await _createSampleAccounts();
    print('💳 Creating sample transactions...');
    await _createSampleTransactions();
    print('🎉 All sample data created successfully!');
  }

  Future<void> _createSampleAccounts() async {
    final sampleAccounts = [
      // Bank Accounts
      Account(
        name: 'HDFC Salary Account',
        type: AccountType.asset,
        subType: AccountSubType.bank,
        balance: 45000.0,
        currency: 'INR',
      ),
      Account(
        name: 'SBI Savings',
        type: AccountType.asset,
        subType: AccountSubType.bank,
        balance: 25000.0,
        currency: 'INR',
      ),

      // Digital Wallets
      Account(
        name: 'Paytm Wallet',
        type: AccountType.asset,
        subType: AccountSubType.digitalWallet,
        balance: 2500.0,
        currency: 'INR',
      ),

      // Cash
      Account(
        name: 'Cash in Hand',
        type: AccountType.asset,
        subType: AccountSubType.cash,
        balance: 5000.0,
        currency: 'INR',
      ),

      // Credit Cards with CIBIL-focused data
      Account(
        name: 'HDFC MoneyBack Card',
        type: AccountType.liability,
        subType: AccountSubType.creditCard,
        balance: 0.0,
        creditLimit: 200000.0,
        outstandingAmount: 45000.0, // 22.5% utilization - Moderate
        currency: 'INR',
        creditCardDetails: CreditCardDetails(
          bankName: 'HDFC Bank',
          cardType: 'Visa',
          cardCategory: 'Cashback',
          cardStatus: 'Active',
          last6Digits: '123456',
          expiryDate: '12/28',
          billingDate: 15,
          dueDate: 5,
          minPaymentAmount: 2250.0,
          rewardRate: '5% on groceries',
          annualFee: 500.0,
          foreignTransactionFee: 3.5,
        ),
      ),

      Account(
        name: 'ICICI Amazon Pay Card',
        type: AccountType.liability,
        subType: AccountSubType.creditCard,
        balance: 0.0,
        creditLimit: 150000.0,
        outstandingAmount: 95000.0, // 63.3% utilization - HIGH
        currency: 'INR',
        creditCardDetails: CreditCardDetails(
          bankName: 'ICICI Bank',
          cardType: 'Visa',
          cardCategory: 'Shopping',
          cardStatus: 'Active',
          last6Digits: '789012',
          expiryDate: '08/27',
          billingDate: 20,
          dueDate: 10,
          minPaymentAmount: 4750.0,
          rewardRate: '5% on Amazon',
          annualFee: 0.0,
          foreignTransactionFee: 3.5,
        ),
      ),

      Account(
        name: 'Axis Bank Neo Card',
        type: AccountType.liability,
        subType: AccountSubType.creditCard,
        balance: 0.0,
        creditLimit: 100000.0,
        outstandingAmount: 15000.0, // 15% utilization - HEALTHY
        currency: 'INR',
        creditCardDetails: CreditCardDetails(
          bankName: 'Axis Bank',
          cardType: 'MasterCard',
          cardCategory: 'Travel',
          cardStatus: 'Active',
          last6Digits: '345678',
          expiryDate: '06/29',
          billingDate: 8,
          dueDate: 28,
          minPaymentAmount: 750.0,
          rewardRate: '2x miles',
          annualFee: 1500.0,
          foreignTransactionFee: 2.0,
        ),
      ),
    ];

    for (var account in sampleAccounts) {
      print('💰 Inserting account: ${account.name}');
      await _dbHelper.insertAccount(account);
      print('✅ Account inserted successfully');
    }
  }

  Future<void> _createSampleTransactions() async {
    final accounts = await _dbHelper.getAccounts();
    final categories = await _dbHelper.getCategories();

    if (accounts.isEmpty || categories.isEmpty) return;

    // Find accounts safely
    final hdfc =
        accounts.where((a) => a.name.contains('HDFC Salary')).isNotEmpty
        ? accounts.firstWhere((a) => a.name.contains('HDFC Salary'))
        : accounts.first;

    final paytm = accounts.where((a) => a.name.contains('Paytm')).isNotEmpty
        ? accounts.firstWhere((a) => a.name.contains('Paytm'))
        : accounts.first;

    final cash = accounts.where((a) => a.name.contains('Cash')).isNotEmpty
        ? accounts.firstWhere((a) => a.name.contains('Cash'))
        : accounts.first;

    final hdfcCc =
        accounts.where((a) => a.name.contains('MoneyBack')).isNotEmpty
        ? accounts.firstWhere((a) => a.name.contains('MoneyBack'))
        : accounts.first;

    final iciciCc = accounts.where((a) => a.name.contains('Amazon')).isNotEmpty
        ? accounts.firstWhere((a) => a.name.contains('Amazon'))
        : accounts.first;

    // Find categories safely
    final salary = categories.where((c) => c.name == 'Salary').isNotEmpty
        ? categories.firstWhere((c) => c.name == 'Salary')
        : categories.first;

    final food = categories.where((c) => c.name == 'Food & Dining').isNotEmpty
        ? categories.firstWhere((c) => c.name == 'Food & Dining')
        : categories.first;

    final transport =
        categories.where((c) => c.name == 'Transportation').isNotEmpty
        ? categories.firstWhere((c) => c.name == 'Transportation')
        : categories.first;

    final shopping = categories.where((c) => c.name == 'Shopping').isNotEmpty
        ? categories.firstWhere((c) => c.name == 'Shopping')
        : categories.first;

    final entertainment =
        categories.where((c) => c.name == 'Entertainment').isNotEmpty
        ? categories.firstWhere((c) => c.name == 'Entertainment')
        : categories.first;

    final groceries = categories.where((c) => c.name == 'Groceries').isNotEmpty
        ? categories.firstWhere((c) => c.name == 'Groceries')
        : categories.first;

    final bills = categories.where((c) => c.name.contains('Bills')).isNotEmpty
        ? categories.firstWhere((c) => c.name.contains('Bills'))
        : categories.first;

    final sampleTransactions = [
      // This month's salary
      Transaction(
        title: 'Monthly Salary',
        amount: 75000.0,
        date: DateTime(2025, 8, 1),
        time: DateTime(2025, 8, 1, 10, 30),
        type: TransactionType.income,
        accountId: hdfc.id!,
        categoryId: salary.id!,
        notes: 'August 2025 salary credit',
      ),

      // Recent expenses
      Transaction(
        title: 'Swiggy Order - Biryani',
        amount: 450.0,
        date: DateTime(2025, 8, 27),
        time: DateTime(2025, 8, 27, 20, 15),
        type: TransactionType.expense,
        accountId: hdfcCc.id!,
        categoryId: food.id!,
        notes: 'Dinner from Biryani Blues',
      ),

      Transaction(
        title: 'Metro Card Recharge',
        amount: 200.0,
        date: DateTime(2025, 8, 27),
        time: DateTime(2025, 8, 27, 8, 45),
        type: TransactionType.expense,
        accountId: paytm.id!,
        categoryId: transport.id!,
        notes: 'Delhi Metro travel card',
      ),

      Transaction(
        title: 'Big Bazaar Groceries',
        amount: 2850.0,
        date: DateTime(2025, 8, 26),
        time: DateTime(2025, 8, 26, 19, 30),
        type: TransactionType.expense,
        accountId: hdfcCc.id!,
        categoryId: groceries.id!,
        notes: 'Monthly grocery shopping',
      ),

      Transaction(
        title: 'Uber Ride to Office',
        amount: 180.0,
        date: DateTime(2025, 8, 26),
        time: DateTime(2025, 8, 26, 9, 15),
        type: TransactionType.expense,
        accountId: hdfc.id!,
        categoryId: transport.id!,
      ),

      Transaction(
        title: 'Amazon Shopping',
        amount: 3200.0,
        date: DateTime(2025, 8, 25),
        time: DateTime(2025, 8, 25, 15, 20),
        type: TransactionType.expense,
        accountId: iciciCc.id!,
        categoryId: shopping.id!,
        notes: 'Electronics and books',
      ),

      Transaction(
        title: 'Electricity Bill',
        amount: 1850.0,
        date: DateTime(2025, 8, 24),
        time: DateTime(2025, 8, 24, 11, 0),
        type: TransactionType.expense,
        accountId: hdfc.id!,
        categoryId: bills.id!,
        notes: 'August electricity bill payment',
      ),

      Transaction(
        title: 'Movie Tickets',
        amount: 600.0,
        date: DateTime(2025, 8, 23),
        time: DateTime(2025, 8, 23, 18, 45),
        type: TransactionType.expense,
        accountId: cash.id!,
        categoryId: entertainment.id!,
        notes: 'PVR Cinema - 2 tickets',
      ),

      Transaction(
        title: 'Zomato Order',
        amount: 320.0,
        date: DateTime(2025, 8, 22),
        time: DateTime(2025, 8, 22, 13, 30),
        type: TransactionType.expense,
        accountId: hdfcCc.id!,
        categoryId: food.id!,
        notes: 'Lunch from office',
      ),

      Transaction(
        title: 'Petrol',
        amount: 2000.0,
        date: DateTime(2025, 8, 21),
        time: DateTime(2025, 8, 21, 16, 20),
        type: TransactionType.expense,
        accountId: hdfc.id!,
        categoryId: transport.id!,
        notes: 'Full tank - Shell petrol pump',
      ),
    ];

    for (var transaction in sampleTransactions) {
      await _dbHelper.insertTransaction(transaction);
    }
  }

  // FEATURE: Clear all data for fresh start
  Future<void> clearAllData() async {
    final db = await _dbHelper.database;
    await db.delete('transactions');
    await db.delete('accounts');
    await db.delete('categories');

    // Recreate default categories using the public method
    await _dbHelper.recreateDefaultCategories();
  }
}
