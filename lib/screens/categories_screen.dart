import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/enums.dart';

// CATEGORIES MANAGEMENT SCREEN - Add, edit, delete expense/income categories
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Category> _categories = [];
  List<Category> _incomeCategories = [];
  List<Category> _expenseCategories = [];
  bool _isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoading = true);

      final categories = await _dbHelper.getCategories();

      setState(() {
        _categories = categories;
        _incomeCategories = categories
            .where((cat) => cat.type == CategoryType.income)
            .toList();
        _expenseCategories = categories
            .where((cat) => cat.type == CategoryType.expense)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() => _isLoading = false);
    }
  }

  void _addNewCategory(CategoryType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(type: type),
      ),
    ).then((_) => _loadCategories());
  }

  void _editCategory(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(category: category),
      ),
    ).then((_) => _loadCategories());
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.deleteCategory(category.id!);
        _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${category.name} deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting category: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Income', icon: Icon(Icons.trending_up)),
            Tab(text: 'Expense', icon: Icon(Icons.trending_down)),
          ],
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCategoriesList(_incomeCategories, CategoryType.income),
                _buildCategoriesList(_expenseCategories, CategoryType.expense),
              ],
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final currentType = _tabController.index == 0
              ? CategoryType.income
              : CategoryType.expense;
          _addNewCategory(currentType);
        },
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoriesList(List<Category> categories, CategoryType type) {
    if (categories.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return _buildCategoryTile(categories[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(CategoryType type) {
    final isIncome = type == CategoryType.income;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isIncome ? Icons.trending_up : Icons.trending_down,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No ${isIncome ? 'income' : 'expense'} categories yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first ${isIncome ? 'income' : 'expense'} category to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _addNewCategory(type),
            icon: const Icon(Icons.add),
            label: Text('Add ${isIncome ? 'Income' : 'Expense'} Category'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(Category category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(
              int.parse(category.color.replaceAll('#', '0xFF')),
            ).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(category.icon, style: const TextStyle(fontSize: 24)),
          ),
        ),

        title: Text(
          category.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),

        subtitle: category.description != null
            ? Text(
                category.description!,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              )
            : null,

        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editCategory(category);
                break;
              case 'delete':
                _deleteCategory(category);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),

        onTap: () => _editCategory(category),
      ),
    );
  }
}

// ADD/EDIT CATEGORY SCREEN
class AddEditCategoryScreen extends StatefulWidget {
  final Category? category;
  final CategoryType? type;

  const AddEditCategoryScreen({super.key, this.category, this.type});

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  CategoryType _selectedType = CategoryType.expense;
  String _selectedIcon = '📂';
  String _selectedColor = '#2196F3';
  bool _isLoading = false;

  // PREDEFINED ICONS FOR CATEGORIES
  final List<String> _availableIcons = [
    // Income icons
    '💰', '💼', '📈', '💵', '🏦', '💳', '🎯', '🎁', '⭐', '✨',
    // Expense icons
    '🍽️', '🚗', '🛍️', '🎬', '⚡', '🏥', '📚', '🏠', '✈️', '☕',
    '🎮', '💊', '👕', '🧴', '🔧', '📱', '🎵', '🏋️', '🚌', '🍕',
    // General icons
    '📂', '💡', '🎨', '🔥', '🌟', '❤️', '🎈', '🌈', '⚽', '🎪',
  ];

  // PREDEFINED COLORS
  final List<String> _availableColors = [
    '#F44336',
    '#E91E63',
    '#9C27B0',
    '#673AB7',
    '#3F51B5',
    '#2196F3',
    '#03DAC6',
    '#4CAF50',
    '#8BC34A',
    '#CDDC39',
    '#FFC107',
    '#FF9800',
    '#FF5722',
    '#795548',
    '#9E9E9E',
    '#607D8B',
    '#000000',
    '#1976D2',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      // EDITING EXISTING CATEGORY
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description ?? '';
      _selectedType = widget.category!.type;
      _selectedIcon = widget.category!.icon;
      _selectedColor = widget.category!.color;
    } else if (widget.type != null) {
      // CREATING NEW CATEGORY WITH SPECIFIED TYPE
      _selectedType = widget.type!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final category = Category(
        id: widget.category?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        type: _selectedType,
        icon: _selectedIcon,
        color: _selectedColor,
      );

      if (widget.category == null) {
        await _dbHelper.insertCategory(category);
      } else {
        await _dbHelper.updateCategory(category);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.category == null
                  ? 'Category created successfully!'
                  : 'Category updated successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving category: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Category' : 'Add Category'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveCategory,
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
              // CATEGORY NAME
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., Groceries, Salary, Entertainment',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter category name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // CATEGORY TYPE (only show if creating new category)
              if (widget.category == null) ...[
                DropdownButtonFormField<CategoryType>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Category Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: CategoryType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(
                            type == CategoryType.income
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: type == CategoryType.income
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type == CategoryType.income ? 'Income' : 'Expense',
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedType = value!);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // DESCRIPTION
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Brief description of this category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // ICON SELECTION
              const Text(
                'Choose Icon',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final icon = _availableIcons[index];
                    final isSelected = _selectedIcon == icon;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = icon),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[100] : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: Colors.blue[700]!, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // COLOR SELECTION
              const Text(
                'Choose Color',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: _availableColors.length,
                  itemBuilder: (context, index) {
                    final color = _availableColors[index];
                    final isSelected = _selectedColor == color;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(color.replaceAll('#', '0xFF')),
                          ),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // PREVIEW
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(_selectedColor.replaceAll('#', '0xFF')),
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _selectedIcon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preview',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            _nameController.text.isEmpty
                                ? 'Category Name'
                                : _nameController.text,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _selectedType == CategoryType.income
                                ? 'Income Category'
                                : 'Expense Category',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCategory,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEditing ? 'Update Category' : 'Create Category'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
