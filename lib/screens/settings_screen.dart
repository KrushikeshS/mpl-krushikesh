import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../widgets/color_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
          // ListTile(
          //   title: const Text('Default Color'),
          //   subtitle: const Text('Choose default brush color'),
          //   trailing: Container(
          //     width: 24,
          //     height: 24,
          //     decoration: BoxDecoration(
          //       color: settings.defaultColor,
          //       shape: BoxShape.circle,
          //       border: Border.all(color: Colors.grey),
          //     ),
          //   ),
          //   onTap: () => _showColorPicker(context, settings),
          // ),
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
          // SwitchListTile(
          //   title: const Text('Auto-save'),
          //   subtitle: const Text('Automatically save drawings'),
          //   value: settings.autosave,
          //   onChanged: (value) => settings.setAutosave(value),
          // ),

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

  void _showColorPicker(BuildContext context, AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Default Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            selectedColor: settings.defaultColor,
            onColorSelected: (color) {
              settings.setDefaultColor(color);
              Navigator.pop(context);
            },
            showLabel: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }
}
