import 'package:LearnLink/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_skills_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  // Settings toggles
  bool _notificationsEnabled = true;
  bool _jobAlertsEnabled = true;
  bool _newsAlertsEnabled = true;
  bool _learningReminders = false;
  bool _emailNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _userData = doc.data();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionHeader('Account', Icons.person_rounded),
            SizedBox(height: AppSpacing.md),
            _buildAccountSection(),

            SizedBox(height: AppSpacing.lg),

            // Notifications Section
            _buildSectionHeader('Notifications', Icons.notifications_rounded),
            SizedBox(height: AppSpacing.md),
            _buildNotificationsSection(),

            SizedBox(height: AppSpacing.lg),

            // Preferences Section
            _buildSectionHeader('Preferences', Icons.tune_rounded),
            SizedBox(height: AppSpacing.md),
            _buildPreferencesSection(),

            SizedBox(height: AppSpacing.lg),

            // Privacy & Security Section
            _buildSectionHeader('Privacy & Security', Icons.lock_rounded),
            SizedBox(height: AppSpacing.md),
            _buildPrivacySection(),

            SizedBox(height: AppSpacing.lg),

            // About Section
            _buildSectionHeader('About', Icons.info_rounded),
            SizedBox(height: AppSpacing.md),
            _buildAboutSection(),

            SizedBox(height: AppSpacing.lg),

            // Danger Zone
            _buildSectionHeader('Danger Zone', Icons.warning_rounded),
            SizedBox(height: AppSpacing.md),
            _buildDangerSection(),

            SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    final userName = _userData?['name'] ?? 'User';
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final skills = _userData?['skills'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            'Name',
            userName,
            Icons.person_outline_rounded,
            onTap: () => _showEditDialog('name', 'Edit Name', userName),
          ),
          Divider(height: 1, color: AppColors.divider),
          _buildSettingItem(
            'Email',
            userEmail,
            Icons.email_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Email cannot be changed from here'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
          ),
          Divider(height: 1, color: AppColors.divider),
          _buildSettingItem(
            'Password',
            '••••••••',
            Icons.lock_outline_rounded,
            onTap: () => _showChangePasswordDialog(),
          ),
          Divider(height: 1, color: AppColors.divider),
          _buildSettingItem(
            'Field of Study',
            _userData?['field'] ?? 'Not set',
            Icons.school_outlined,
            onTap: () => _showFieldSelector(),
          ),
          Divider(height: 1, color: AppColors.divider),
          _buildSettingItem(
            'Skills',
            '${skills.length} skills added',
            Icons.verified_outlined,
            onTap: () => _navigateToEditSkills(skills),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildSwitchItem(
            'Push Notifications',
            'Receive push notifications',
            Icons.notifications_active_outlined,
            _notificationsEnabled,
                (value) => setState(() => _notificationsEnabled = value),
          ),
          Divider(height: 1, color: AppColors.divider),
          _buildSwitchItem(
            'Job Alerts',
            'Get notified about new job matches',
            Icons.work_outline_rounded,
            _jobAlertsEnabled,
                (value) => setState(() => _jobAlertsEnabled = value),
          ),
          Divider(height: 1, color: AppColors.divider),
          _buildSwitchItem(
            'News Updates',
            'Industry news notifications',
            Icons.newspaper_outlined,
            _newsAlertsEnabled,
                (value) => setState(() => _newsAlertsEnabled = value),
          ),
          Divider(height: 1, color: AppColors.divider),
          _buildSwitchItem(
            'Learning Reminders',
            'Daily reminders to continue learning',
            Icons.school_outlined,
            _learningReminders,
                (value) => setState(() => _learningReminders = value),
          ),
          Divider(height: 1, color: AppColors.divider),
          _buildSwitchItem(
            'Email Notifications',
            'Receive updates via email',
            Icons.email_outlined,
            _emailNotifications,
                (value) => setState(() => _emailNotifications = value),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            'Language',
            'English',
            Icons.language_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Language selection coming soon!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          Divider(height: 1, color: AppColors.divider),
          _buildSettingItem(
            'Theme',
            'Light Mode',
            Icons.palette_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Theme customization coming soon!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          Divider(height: 1, color: AppColors.divider),
          _buildSettingItem(
            'Data Usage',
            'Standard quality',
            Icons.data_usage_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Data settings coming soon!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            'Privacy Policy',
            'View our privacy policy',
            Icons.privacy_tip_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening privacy policy...'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          Divider(height: 1, color: AppColors.divider),
          _buildSettingItem(
            'Terms of Service',
            'View terms and conditions',
            Icons.description_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening terms of service...'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          Divider(height: 1, color: AppColors.divider),
          _buildSettingItem(
            'Data & Privacy',
            'Manage your data',
            Icons.shield_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Data management coming soon!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            'Version',
            '1.0.0',
            Icons.info_outline_rounded,
            showArrow: false,
          ),
          Divider(height: 1, color: AppColors.divider),
          _buildSettingItem(
            'Help Center',
            'Get help and support',
            Icons.help_outline_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Help center coming soon!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          Divider(height: 1, color: AppColors.divider),
          _buildSettingItem(
            'Send Feedback',
            'Share your thoughts',
            Icons.feedback_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Feedback form coming soon!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          Divider(height: 1, color: AppColors.divider),
          _buildSettingItem(
            'Rate App',
            'Rate us on the store',
            Icons.star_outline_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Thank you for your support!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            'Clear Cache',
            'Free up storage space',
            Icons.delete_outline_rounded,
            isDestructive: true,
            onTap: () => _showConfirmDialog(
              'Clear Cache',
              'This will clear all cached data. Continue?',
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cache cleared successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, color: AppColors.divider),
          _buildSettingItem(
            'Delete Account',
            'Permanently delete your account',
            Icons.person_remove_outlined,
            isDestructive: true,
            onTap: () => _showDeleteAccountDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
      String title,
      String subtitle,
      IconData icon, {
        VoidCallback? onTap,
        bool showArrow = true,
        bool isDestructive = false,
      }) {
    final color = isDestructive ? AppColors.error : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (showArrow && onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem(
      String title,
      String subtitle,
      IconData icon,
      bool value,
      ValueChanged<bool> onChanged,
      ) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String field, String title, String currentValue) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter $field',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
          ),
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
            onPressed: () async {
              final newValue = controller.text.trim();
              if (newValue.isNotEmpty) {
                await _updateUserField(field, newValue);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title updated successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password'),
        content: Text('Password reset email will be sent to your registered email address.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = FirebaseAuth.instance.currentUser?.email;
              if (email != null) {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset email sent!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Send Email'),
          ),
        ],
      ),
    );
  }

  void _showFieldSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Field of Study'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppConstants.courseFields.length,
            itemBuilder: (context, index) {
              final field = AppConstants.courseFields[index];
              return ListTile(
                title: Text(field),
                onTap: () async {
                  await _updateUserField('field', field);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Field updated successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
      ),
    );
  }

  void _showConfirmDialog(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
          'This action cannot be undone. All your data will be permanently deleted.',
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Account deletion coming soon'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEditSkills(List<dynamic> currentSkills) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSkillsScreen(
          initialSkills: currentSkills.map((s) => s.toString()).toList(),
        ),
      ),
    );

    // Reload user data if skills were updated
    if (result != null) {
      await _loadUserData();
    }
  }

  Future<void> _updateUserField(String field, String value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({field: value});
        await _loadUserData();
      }
    } catch (e) {
      print('Error updating field: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update $field'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}