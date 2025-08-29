import '../services/sample_data_service.dart';
import '../services/data_export_import_service.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // APP PREFERENCES SECTION
            _buildSectionTitle('App Preferences'),
            const SizedBox(height: 12),

            // THEME TOGGLE
            _buildSettingsTile(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              subtitle: 'Switch between light and dark theme',
              trailing: Switch(
                value: themeNotifier.isDarkMode,
                onChanged: (value) {
                  setState(() {
                    themeNotifier.toggleTheme();
                  });
                },
                activeThumbColor: const Color(0xFF1A237E),
              ),
            ),

            // CATEGORIES MANAGEMENT
            _buildSettingsTile(
              icon: Icons.category,
              title: 'Categories',
              subtitle: 'Manage income and expense categories',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoriesScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // DATA & BACKUP SECTION
            _buildSectionTitle('Data & Backup'),
            const SizedBox(height: 12),

            _buildSettingsTile(
              icon: Icons.cloud_upload,
              title: 'Export Data',
              subtitle: 'Export your data as CSV file',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _exportData(context),
            ),

            _buildSettingsTile(
              icon: Icons.cloud_download,
              title: 'Import Data',
              subtitle: 'Import data from CSV file',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _importData(context),
            ),
            _buildSettingsTile(
              icon: Icons.data_usage,
              title: 'Load Sample Data',
              subtitle: 'Import realistic test data for practice',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _loadSampleData(context),
            ),

            _buildSettingsTile(
              icon: Icons.clear_all,
              title: 'Clear All Data',
              subtitle: 'Delete all accounts and transactions',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _clearAllData(context),
            ),

            _buildSettingsTile(
              icon: Icons.backup,
              title: 'Auto Backup',
              subtitle: 'Automatically backup your data',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showComingSoon(context, 'Auto Backup'),
            ),

            const SizedBox(height: 32),

            // NOTIFICATIONS SECTION
            _buildSectionTitle('Notifications'),
            const SizedBox(height: 12),

            _buildSettingsTile(
              icon: Icons.notifications,
              title: 'Daily Reminders',
              subtitle: 'Get reminded to log your expenses',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showComingSoon(context, 'Daily Reminders'),
            ),

            _buildSettingsTile(
              icon: Icons.settings,
              title: 'Budget Alerts',
              subtitle: 'Get notified when you exceed budgets',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showComingSoon(context, 'Budget Alerts'),
            ),

            const SizedBox(height: 32),

            // REPORTS SECTION
            _buildSectionTitle('Reports & Analytics'),
            const SizedBox(height: 12),

            _buildSettingsTile(
              icon: Icons.pie_chart,
              title: 'Spending Analysis',
              subtitle: 'View detailed spending patterns',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showComingSoon(context, 'Spending Analysis'),
            ),

            _buildSettingsTile(
              icon: Icons.trending_up,
              title: 'Monthly Reports',
              subtitle: 'Generate monthly financial reports',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showComingSoon(context, 'Monthly Reports'),
            ),

            _buildSettingsTile(
              icon: Icons.compare_arrows,
              title: 'Budget vs Actual',
              subtitle: 'Compare budgets with actual spending',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showComingSoon(context, 'Budget vs Actual'),
            ),

            const SizedBox(height: 32),

            // SECURITY SECTION
            _buildSectionTitle('Security & Privacy'),
            const SizedBox(height: 12),

            _buildSettingsTile(
              icon: Icons.lock,
              title: 'App Lock',
              subtitle: 'Secure your app with PIN or biometrics',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showComingSoon(context, 'App Lock'),
            ),

            _buildSettingsTile(
              icon: Icons.privacy_tip,
              title: 'Privacy Settings',
              subtitle: 'Control your data privacy preferences',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showComingSoon(context, 'Privacy Settings'),
            ),

            const SizedBox(height: 32),

            // ABOUT SECTION
            _buildSectionTitle('About'),
            const SizedBox(height: 12),

            _buildSettingsTile(
              icon: Icons.info,
              title: 'App Version',
              subtitle: 'Kora Expense Tracker v1.0.0',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showAboutDialog(context),
            ),

            _buildSettingsTile(
              icon: Icons.rate_review,
              title: 'Rate App',
              subtitle: 'Rate us on the app store',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showComingSoon(context, 'Rate App'),
            ),

            _buildSettingsTile(
              icon: Icons.help,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showComingSoon(context, 'Help & Support'),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A237E),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1A237E), size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.upcoming, color: Color(0xFF1A237E)),
            ),
            const SizedBox(width: 12),
            const Text('Coming Soon'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$feature is coming in a future update!'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3F51B5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.rocket_launch, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Stay tuned for exciting updates!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Kora Expense Tracker',
      applicationVersion: 'v1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF3F51B5)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.account_balance_wallet,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: const [
        Text(
          'A beautiful and intuitive expense tracking app to help you manage your finances effortlessly.',
        ),
        SizedBox(height: 16),
        Text('Built with ❤️ using Flutter'),
      ],
    );
  }

  Future<void> _loadSampleData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.data_usage, color: Color(0xFF1A237E)),
            ),
            const SizedBox(width: 12),
            const Text('Load Sample Data'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This will create:'),
            SizedBox(height: 12),
            Text('• 7 Sample accounts (including credit cards)'),
            Text('• 10 Recent transactions'),
            Text('• Realistic Indian expense data'),
            SizedBox(height: 16),
            Text('Perfect for testing features!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Load Sample Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        print('🚀 Loading sample data started...');
        await SampleDataService().loadSampleData();
        print('✅ Sample data loading completed!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sample data loaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Force refresh by popping back to dashboard
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading sample data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Clear All Data'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⚠️ This will permanently delete:'),
            SizedBox(height: 12),
            Text('• All accounts'),
            Text('• All transactions'),
            Text('• All custom categories'),
            SizedBox(height: 16),
            Text('This action cannot be undone!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SampleDataService().clearAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data cleared successfully!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Export data functionality
  Future<void> _exportData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud_upload, color: Color(0xFF1A237E)),
            ),
            const SizedBox(width: 12),
            const Text('Export Data'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This will export all your data to CSV files:'),
            SizedBox(height: 12),
            Text('• accounts.csv - All your accounts'),
            Text('• categories.csv - All categories'),
            Text('• transactions.csv - All transactions'),
            Text('• export_summary.txt - Export details'),
            SizedBox(height: 16),
            Text('You can share or save these files for backup.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Exporting data...'),
              ],
            ),
          ),
        );

        final exportService = DataExportImportService();
        final exportPath = await exportService.exportDataToCSV();
        
        // Close loading dialog
        Navigator.pop(context);

        // Show success dialog with share option
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green),
                ),
                const SizedBox(width: 12),
                const Text('Export Successful'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your data has been exported successfully!'),
                const SizedBox(height: 16),
                Text('Files saved to:\n$exportPath'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await exportService.shareExportedData(exportPath);
                },
                child: const Text('Share Files'),
              ),
            ],
          ),
        );
      } catch (e) {
        // Close loading dialog if open
        Navigator.pop(context);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Import data functionality
  Future<void> _importData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            const Text('Import Data'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⚠️ Important:'),
            SizedBox(height: 12),
            Text('• This will ADD data to your existing records'),
            Text('• Select CSV files exported from Kora'),
            Text('• You can select multiple files at once'),
            Text('• Make sure files are in correct CSV format'),
            SizedBox(height: 16),
            Text('Supported files: accounts.csv, categories.csv, transactions.csv'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Select Files'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Importing data...'),
              ],
            ),
          ),
        );

        final exportService = DataExportImportService();
        final results = await exportService.importDataFromCSV();
        
        // Close loading dialog
        Navigator.pop(context);

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green),
                ),
                const SizedBox(width: 12),
                const Text('Import Successful'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Data imported successfully!'),
                const SizedBox(height: 16),
                Text('Imported:'),
                Text('• ${results['accounts']} accounts'),
                Text('• ${results['categories']} categories'),
                Text('• ${results['transactions']} transactions'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Go back to dashboard to see imported data
                  Navigator.of(context).pop();
                },
                child: const Text('View Dashboard'),
              ),
            ],
          ),
        );
      } catch (e) {
        // Close loading dialog if open
        Navigator.pop(context);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
