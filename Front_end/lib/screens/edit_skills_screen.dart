import 'package:LearnLink/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class EditSkillsScreen extends StatefulWidget {
  final List<String> initialSkills;

  const EditSkillsScreen({Key? key, required this.initialSkills}) : super(key: key);

  @override
  State<EditSkillsScreen> createState() => _EditSkillsScreenState();
}

class _EditSkillsScreenState extends State<EditSkillsScreen> with SingleTickerProviderStateMixin {
  late List<String> _selectedSkills;
  List<String> _availableSkills = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isSaving = false;
  late TabController _tabController;

  final Map<String, List<String>> _skillCategories = {
    'Technology': AppConstants.technologySkills,
    'Business': AppConstants.businessSkills,
    'Film & Media': AppConstants.filmMediaSkills,
    'Healthcare': AppConstants.healthcareSkills,
    'Engineering': AppConstants.engineeringSkills,
    'Design': AppConstants.designSkills,
    'Marketing': AppConstants.marketingSkills,
    'Finance': AppConstants.financeSkills,
    'Education': AppConstants.educationSkills,
    'Arts': AppConstants.artsSkills,
  };

  @override
  void initState() {
    super.initState();
    _selectedSkills = List.from(widget.initialSkills);
    _tabController = TabController(length: _skillCategories.length + 1, vsync: this);
    _loadAvailableSkills();
  }

  void _loadAvailableSkills() {
    // Combine all skills from all categories
    Set<String> allSkills = {};
    _skillCategories.forEach((key, value) {
      allSkills.addAll(value);
    });
    setState(() {
      _availableSkills = allSkills.toList()..sort();
    });
  }

  List<String> _getFilteredSkills() {
    List<String> skills = [];

    if (_selectedCategory == 'All') {
      skills = _availableSkills;
    } else {
      skills = _skillCategories[_selectedCategory] ?? [];
    }

    if (_searchQuery.isNotEmpty) {
      skills = skills.where((skill) =>
          skill.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return skills;
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  Future<void> _saveSkills() async {
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one skill'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'skills': _selectedSkills});

        if (mounted) {
          Navigator.pop(context, _selectedSkills);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Skills updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving skills: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update skills'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _addCustomSkill() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Custom Skill'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter skill name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final skill = controller.text.trim();
              if (skill.isNotEmpty) {
                setState(() {
                  if (!_selectedSkills.contains(skill)) {
                    _selectedSkills.add(skill);
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Skill "$skill" added'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Skills',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveSkills,
            icon: _isSaving
                ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            )
                : Icon(Icons.check_rounded, size: 20),
            label: Text('Save'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          // Selected Skills Section
          _buildSelectedSkillsSection(),

          // Search Bar
          _buildSearchBar(),

          // Category Tabs
          _buildCategoryTabs(),

          // Available Skills Grid
          Expanded(
            child: _buildSkillsGrid(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomSkill,
        backgroundColor: AppColors.primary,
        icon: Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Custom Skill',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedSkillsSection() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, size: 20, color: AppColors.success),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Selected Skills (${_selectedSkills.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _selectedSkills.isEmpty
              ? Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: AppColors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'No skills selected. Tap skills below to add them.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
              : Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _selectedSkills.map((skill) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skill,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: () => _toggleSkill(skill),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      color: AppColors.surface,
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search skills...',
          hintStyle: TextStyle(color: AppColors.textTertiary),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear_rounded, color: AppColors.textSecondary),
            onPressed: () => setState(() => _searchQuery = ''),
          )
              : null,
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        onTap: (index) {
          setState(() {
            if (index == 0) {
              _selectedCategory = 'All';
            } else {
              _selectedCategory = _skillCategories.keys.toList()[index - 1];
            }
          });
        },
        tabs: [
          Tab(text: 'All'),
          ..._skillCategories.keys.map((category) => Tab(text: category)),
        ],
      ),
    );
  }

  Widget _buildSkillsGrid() {
    final filteredSkills = _getFilteredSkills();

    if (filteredSkills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'No skills found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Try a different search or category',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: filteredSkills.length,
      itemBuilder: (context, index) {
        final skill = filteredSkills[index];
        final isSelected = _selectedSkills.contains(skill);

        return GestureDetector(
          onTap: () => _toggleSkill(skill),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected) ...[
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    skill,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}