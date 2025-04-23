import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../widgets/color_picker.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, authService),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Theme Settings
          _buildSectionHeader(context, 'Theme'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: settings.darkMode,
            onChanged: (value) => settings.setDarkMode(value),
          ),

          // Drawing Settings
          _buildSectionHeader(context, 'Drawing Defaults'),
          ListTile(
            title: const Text('Default Brush Size'),
            subtitle: Text('${settings.defaultStrokeWidth.toInt()} px'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: settings.defaultStrokeWidth,
                min: 1.0,
                max: 20.0,
                divisions: 19,
                onChanged: (value) => settings.setDefaultStrokeWidth(value),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Show Grid'),
            subtitle: const Text('Display grid on canvas'),
            value: settings.showGrid,
            onChanged: (value) => settings.setShowGrid(value),
          ),

          // Account Settings
          _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: Text(
                FirebaseAuth.instance.currentUser?.email ?? 'Not signed in'),
            subtitle: const Text('Current account'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _showLogoutDialog(context, authService),
          ),

          // About Section
          _buildSectionHeader(context, 'About'),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(
      BuildContext context, AuthService authService) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('LOGOUT'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      try {
        await authService.signOut();
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error logging out: $e')),
          );
        }
      }
    }
  }
}
