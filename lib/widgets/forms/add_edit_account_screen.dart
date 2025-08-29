import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/account.dart';
import '../../models/enums.dart';
import '../../utils/formatters/expiry_date_formatter.dart';

class AddEditAccountScreen extends StatefulWidget {
  final Account? account;
  final VoidCallback? onAccountChanged;

  const AddEditAccountScreen({super.key, this.account, this.onAccountChanged});

  @override
  State<AddEditAccountScreen> createState() => _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends State<AddEditAccountScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _outstandingController = TextEditingController();

  // Credit Card specific controllers
  final _bankNameController = TextEditingController();
  final _cardTypeController = TextEditingController();
  final _cardCategoryController = TextEditingController();
  final _last6DigitsController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _rewardRateController = TextEditingController();
  final _annualFeeController = TextEditingController();
  final _foreignFeeController = TextEditingController();
  final _minPaymentController = TextEditingController();

  // Credit Card dropdowns
  String _selectedBankName = 'HDFC Bank';
  String _selectedCardType = 'Visa';
  String _selectedCardCategory = 'Rewards';
  String _selectedCardStatus = 'Active';
  int? _billingDate;
  int? _dueDate;

  // Indian Banks
  final List<String> _indianBanks = [
    'HDFC Bank',
    'ICICI Bank',
    'State Bank of India',
    'Axis Bank',
    'Kotak Mahindra Bank',
    'Yes Bank',
    'IndusInd Bank',
    'IDFC First Bank',
    'RBL Bank',
    'Standard Chartered',
    'Citibank',
    'HSBC',
    'American Express',
    'Punjab National Bank',
    'Bank of Baroda',
    'Canara Bank',
    'Union Bank',
  ];

  final List<String> _cardTypes = [
    'Visa',
    'MasterCard',
    'American Express',
    'RuPay',
    'Diners Club',
  ];

  final List<String> _cardCategories = [
    'Rewards',
    'Cashback',
    'Travel',
    'Fuel',
    'Shopping',
    'Dining',
    'Premium',
  ];

  final List<String> _cardStatuses = ['Active', 'Inactive', 'Blocked', 'Lost'];

  AccountType _selectedType = AccountType.asset;
  AccountSubType _selectedSubType = AccountSubType.bank;
  String _selectedCurrency = 'INR';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _populateFields();
    } else if (_selectedSubType == AccountSubType.creditCard) {
      _balanceController.text = '0';
    }
  }

  void _populateFields() {
    final account = widget.account!;
    _nameController.text = account.name;
    _balanceController.text = account.balance.toString();
    _selectedType = account.type;
    _selectedSubType = account.subType;
    _selectedCurrency = account.currency;

    if (account.creditLimit != null) {
      _creditLimitController.text = account.creditLimit.toString();
    }

    if (account.outstandingAmount != null) {
      _outstandingController.text = account.outstandingAmount.toString();
    }

    if (account.creditCardDetails != null) {
      final cardDetails = account.creditCardDetails!;
      _selectedBankName = cardDetails.bankName ?? 'HDFC Bank';
      _selectedCardType = cardDetails.cardType ?? 'Visa';
      _selectedCardCategory = cardDetails.cardCategory ?? 'Rewards';
      _selectedCardStatus = cardDetails.cardStatus ?? 'Active';
      _last6DigitsController.text = cardDetails.last6Digits ?? '';
      _expiryDateController.text = cardDetails.expiryDate ?? '';
      _rewardRateController.text = cardDetails.rewardRate ?? '';
      _annualFeeController.text = cardDetails.annualFee?.toString() ?? '';
      _foreignFeeController.text =
          cardDetails.foreignTransactionFee?.toString() ?? '';
      _minPaymentController.text =
          cardDetails.minPaymentAmount?.toString() ?? '';
      _billingDate = cardDetails.billingDate;
      _dueDate = cardDetails.dueDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _creditLimitController.dispose();
    _outstandingController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      CreditCardDetails? creditCardDetails;

      if (_selectedSubType == AccountSubType.creditCard) {
        creditCardDetails = CreditCardDetails(
          last6Digits: _last6DigitsController.text.trim().isEmpty
              ? null
              : _last6DigitsController.text.trim(),
          bankName: _selectedBankName,
          cardType: _selectedCardType,
          cardCategory: _selectedCardCategory,
          cardStatus: _selectedCardStatus,
          expiryDate: _expiryDateController.text.trim().isEmpty
              ? null
              : _expiryDateController.text.trim(),
          billingDate: _billingDate,
          dueDate: _dueDate,
          minPaymentAmount: _minPaymentController.text.trim().isEmpty
              ? null
              : double.tryParse(_minPaymentController.text.trim()),
          rewardRate: _rewardRateController.text.trim().isEmpty
              ? null
              : _rewardRateController.text.trim(),
          annualFee: _annualFeeController.text.trim().isEmpty
              ? null
              : double.tryParse(_annualFeeController.text.trim()),
          foreignTransactionFee: _foreignFeeController.text.trim().isEmpty
              ? null
              : double.tryParse(_foreignFeeController.text.trim()),
        );
      }

      // Handle empty balance - default to 0
      final balanceText = _balanceController.text.trim();
      final balance = balanceText.isEmpty ? 0.0 : double.parse(balanceText);

      final account = Account(
        id: widget.account?.id,
        name: _nameController.text.trim(),
        type: _selectedType,
        subType: _selectedSubType,
        balance: balance,
        creditLimit: _creditLimitController.text.isNotEmpty
            ? double.parse(_creditLimitController.text.trim())
            : null,
        outstandingAmount: _outstandingController.text.isNotEmpty
            ? double.parse(_outstandingController.text.trim())
            : null,
        currency: _selectedCurrency,
        creditCardDetails: creditCardDetails,
      );

      bool shouldCreateAdjustment = false;
      if (widget.account != null) {
        final balanceDifference = account.balance - widget.account!.balance;
        if (balanceDifference != 0) {
          final shouldAdjust = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Balance Changed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance changed by ₹${NumberFormat('#,##,###.##').format(balanceDifference.abs())}',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Would you like to create an adjustment transaction to reflect this change?',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No, just update balance'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes, create adjustment'),
                ),
              ],
            ),
          );
          shouldCreateAdjustment = shouldAdjust ?? false;
        }
      }

      if (widget.account == null) {
        await _dbHelper.insertAccount(account);
      } else {
        await _dbHelper.updateAccount(
          account,
          adjustBalance: shouldCreateAdjustment,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        widget.onAccountChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.account == null
                  ? 'Account created successfully!'
                  : 'Account updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Account' : 'Add Account'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveAccount,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  hintText: 'e.g., HDFC Savings, Cash Wallet',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_circle),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter account name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AccountType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: AccountType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type == AccountType.asset ? 'Asset' : 'Liability',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    if (_selectedType == AccountType.asset) {
                      _selectedSubType = AccountSubType.bank;
                    } else {
                      _selectedSubType = AccountSubType.creditCard;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AccountSubType>(
                initialValue: _selectedSubType,
                decoration: const InputDecoration(
                  labelText: 'Account Sub-Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
                items: _getSubTypeOptions().map((subType) {
                  return DropdownMenuItem(
                    value: subType,
                    child: Text(_getSubTypeLabel(subType)),
                  );
                }).toList(),
                onChanged: (AccountSubType? value) {
                  setState(() {
                    _selectedSubType = value!;
                    if (_selectedSubType == AccountSubType.creditCard &&
                        widget.account == null) {
                      _balanceController.text = '0';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: _selectedType == AccountType.asset
                      ? 'Current Balance'
                      : 'Current Balance',
                  hintText: '0.00 (Leave empty for zero)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.currency_rupee),
                  helperText: 'Leave empty to start with zero balance',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  // Allow empty value - will default to 0
                  if (value != null && value.trim().isNotEmpty) {
                    if (double.tryParse(value.trim()) == null) {
                      return 'Please enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Credit Card specific fields
              if (_selectedSubType == AccountSubType.creditCard) ...[
                TextFormField(
                  controller: _creditLimitController,
                  decoration: const InputDecoration(
                    labelText: 'Credit Limit *',
                    hintText: '₹ 2,00,000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_score),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Credit limit is required for credit cards';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _outstandingController,
                  decoration: const InputDecoration(
                    labelText: 'Outstanding Amount',
                    hintText: '₹ 0 (Auto-calculated from transactions)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payment),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (double.tryParse(value.trim()) == null) {
                        return 'Please enter a valid number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _buildCreditCardForm(),
              ],
              DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                items: const [
                  DropdownMenuItem(value: 'INR', child: Text('INR (₹)')),
                  DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                ],
                onChanged: (value) {
                  setState(() => _selectedCurrency = value!);
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAccount,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEditing ? 'Update Account' : 'Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditCardForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Credit Card Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedBankName,
            decoration: const InputDecoration(
              labelText: 'Bank Name *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.account_balance),
            ),
            items: _indianBanks
                .map((bank) => DropdownMenuItem(value: bank, child: Text(bank)))
                .toList(),
            onChanged: (value) => setState(() => _selectedBankName = value!),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCardType,
                  decoration: const InputDecoration(
                    labelText: 'Card Type *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  items: _cardTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCardType = value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCardCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _cardCategories
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCardCategory = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Flexible(
                child: TextFormField(
                  controller: _last6DigitsController,
                  decoration: const InputDecoration(
                    labelText: 'Last 6 Digits (Optional)',
                    hintText: '●●●●●● 1234',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCardStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info),
                  ),
                  items: _cardStatuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCardStatus = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Flexible(
                child: TextFormField(
                  controller: _expiryDateController,
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date (MM/YY)',
                    hintText: '12/28',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.date_range),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ExpiryDateFormatter(),
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                        return 'Enter valid format MM/YY';
                      }
                      final parts = value.split('/');
                      final month = int.tryParse(parts[0]);
                      if (month == null || month < 1 || month > 12) {
                        return 'Invalid month';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: TextFormField(
                  controller: _minPaymentController,
                  decoration: const InputDecoration(
                    labelText: 'Min Payment',
                    hintText: '₹ 2,000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payment),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Flexible(
                child: TextFormField(
                  controller: _rewardRateController,
                  decoration: const InputDecoration(
                    labelText: 'Reward Rate',
                    hintText: '2 pts/₹100 or 5% cashback',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.card_giftcard),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: TextFormField(
                  controller: _annualFeeController,
                  decoration: const InputDecoration(
                    labelText: 'Annual Fee',
                    hintText: '₹ 2,999',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monetization_on),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _foreignFeeController,
            decoration: const InputDecoration(
              labelText: 'Foreign Transaction Fee (%)',
              hintText: '3.5',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.public),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final fee = double.tryParse(value);
                if (fee == null || fee < 0 || fee > 100) {
                  return 'Enter percentage between 0-100';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _billingDate,
                  decoration: const InputDecoration(
                    labelText: 'Billing Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  hint: const Text('Select Day'),
                  items: List.generate(31, (i) => i + 1)
                      .map(
                        (day) => DropdownMenuItem(
                          value: day,
                          child: Text('${day}th'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _billingDate = value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _dueDate,
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  hint: const Text('Select Day'),
                  items: List.generate(31, (i) => i + 1)
                      .map(
                        (day) => DropdownMenuItem(
                          value: day,
                          child: Text('${day}th'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _dueDate = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<AccountSubType> _getSubTypeOptions() {
    if (_selectedType == AccountType.asset) {
      return [
        AccountSubType.bank,
        AccountSubType.cash,
        AccountSubType.digitalWallet,
        AccountSubType.investment,
      ];
    } else {
      return [
        AccountSubType.creditCard,
        AccountSubType.loan,
        AccountSubType.debt,
      ];
    }
  }

  String _getSubTypeLabel(AccountSubType subType) {
    switch (subType) {
      case AccountSubType.bank:
        return 'Bank Account';
      case AccountSubType.cash:
        return 'Cash';
      case AccountSubType.digitalWallet:
        return 'Digital Wallet';
      case AccountSubType.investment:
        return 'Investment';
      case AccountSubType.creditCard:
        return 'Credit Card';
      case AccountSubType.loan:
        return 'Loan';
      case AccountSubType.debt:
        return 'Other Debt';
    }
  }
}
