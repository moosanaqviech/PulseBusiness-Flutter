// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _marketingEmails = false;
  bool _darkMode = false;
  String _language = 'English';
  String _currency = 'CAD';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _marketingEmails = prefs.getBool('marketing_emails') ?? false;
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _language = prefs.getString('language') ?? 'English';
      _currency = prefs.getString('currency') ?? 'CAD';
    });
  }

  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('email_notifications', _emailNotifications);
    await prefs.setBool('push_notifications', _pushNotifications);
    await prefs.setBool('marketing_emails', _marketingEmails);
    await prefs.setBool('dark_mode', _darkMode);
    await prefs.setString('language', _language);
    await prefs.setString('currency', _currency);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            'Enable Notifications',
            'Receive notifications about your business',
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
          ),
          if (_notificationsEnabled) ...[
            _buildSwitchTile(
              'Push Notifications',
              'Get notified about deals and customers',
              _pushNotifications,
              (value) => setState(() => _pushNotifications = value),
            ),
            _buildSwitchTile(
              'Email Notifications',
              'Receive important updates via email',
              _emailNotifications,
              (value) => setState(() => _emailNotifications = value),
            ),
            _buildSwitchTile(
              'Marketing Emails',
              'Get tips and promotional content',
              _marketingEmails,
              (value) => setState(() => _marketingEmails = value),
            ),
          ],
          
          const SizedBox(height: 24),
          _buildSectionHeader('Appearance'),
          _buildSwitchTile(
            'Dark Mode',
            'Use dark theme throughout the app',
            _darkMode,
            (value) => setState(() => _darkMode = value),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Preferences'),
          _buildDropdownTile(
            'Language',
            'Choose your preferred language',
            _language,
            ['English', 'French', 'Spanish'],
            (value) => setState(() => _language = value!),
          ),
          _buildDropdownTile(
            'Currency',
            'Default currency for pricing',
            _currency,
            ['CAD', 'USD', 'EUR', 'GBP'],
            (value) => setState(() => _currency = value!),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Account'),
          _buildTile(
            'Change Password',
            'Update your account password',
            Icons.lock_outline,
            () => _showChangePasswordDialog(),
          ),
          _buildTile(
            'Privacy Policy',
            'View our privacy policy',
            Icons.privacy_tip_outlined,
            () => _showPrivacyPolicy(),
          ),
          _buildTile(
            'Terms of Service',
            'Read our terms and conditions',
            Icons.description_outlined,
            () => _showTermsOfService(),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Support'),
          _buildTile(
            'Help Center',
            'Get help and support',
            Icons.help_outline,
            () => _showHelpCenter(),
          ),
          _buildTile(
            'Contact Us',
            'Get in touch with our team',
            Icons.email_outlined,
            () => _contactSupport(),
          ),
          _buildTile(
            'Rate App',
            'Rate Pulse Business on the app store',
            Icons.star_outline,
            () => _rateApp(),
          ),
          
          const SizedBox(height: 32),
          _buildDangerSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildDropdownTile(String title, String subtitle, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDangerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danger Zone',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete Account'),
            subtitle: const Text('Permanently delete your account and all data'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showDeleteAccountDialog(),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    // TODO: Implement change password
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('This feature will be available soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    // TODO: Show privacy policy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy policy will be available soon')),
    );
  }

  void _showTermsOfService() {
    // TODO: Show terms of service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terms of service will be available soon')),
    );
  }

  void _showHelpCenter() {
    // TODO: Open help center
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help center will be available soon')),
    );
  }

  void _contactSupport() {
    // TODO: Open email client or contact form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact support: support@pulse.com')),
    );
  }

  void _rateApp() {
    // TODO: Open app store rating
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you! Rating feature coming soon')),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion will be available soon'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}