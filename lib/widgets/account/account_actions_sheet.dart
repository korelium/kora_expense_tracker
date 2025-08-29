// import 'package:flutter/material.dart';
// import '../../models/account.dart';
// import '../../models/category.dart';
// import '../add_transaction_screen.dart';

import 'package:flutter/material.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../screens/add_transaction_screen.dart';

class AccountActionsSheet extends StatelessWidget {
  final Account account;
  final List<Account> accounts;
  final List<Category> categories;
  final VoidCallback onAccountUpdated;
  final VoidCallback onEditAccount;
  final VoidCallback onDeleteAccount;

  const AccountActionsSheet({
    super.key,
    required this.account,
    required this.accounts,
    required this.categories,
    required this.onAccountUpdated,
    required this.onEditAccount,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            account.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // ADD INCOME
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add_circle_outline, color: Colors.green[700]),
            ),
            title: const Text('Add Income'),
            subtitle: const Text('Record money coming in'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(
                    accounts: accounts,
                    categories: categories,
                    selectedAccount: account,
                    initialTransactionType: 'income',
                  ),
                ),
              ).then((_) => onAccountUpdated());
            },
          ),
          // ADD EXPENSE
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.remove_circle_outline, color: Colors.red[700]),
            ),
            title: const Text('Add Expense'),
            subtitle: const Text('Record money going out'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(
                    accounts: accounts,
                    categories: categories,
                    selectedAccount: account,
                    initialTransactionType: 'expense',
                  ),
                ),
              ).then((_) => onAccountUpdated());
            },
          ),
          // ADD TRANSFER
          if (accounts.length > 1)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.swap_horiz, color: Colors.blue[700]),
              ),
              title: const Text('Transfer Money'),
              subtitle: const Text('Move money between accounts'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTransactionScreen(
                      accounts: accounts,
                      categories: categories,
                      selectedAccount: account,
                      initialTransactionType: 'transfer',
                    ),
                  ),
                ).then((_) => onAccountUpdated());
              },
            ),
          // EDIT ACCOUNT
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.edit, color: Colors.blue[700]),
            ),
            title: const Text('Edit Account'),
            subtitle: const Text('Modify account details'),
            onTap: () {
              Navigator.pop(context);
              onEditAccount();
            },
          ),
          // DELETE ACCOUNT
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete, color: Colors.red[700]),
            ),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Remove account permanently'),
            onTap: () {
              Navigator.pop(context);
              onDeleteAccount();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
