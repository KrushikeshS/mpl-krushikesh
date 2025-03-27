import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Logo
          const SizedBox(height: 20),
          Icon(
            Icons.brush,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          
          // App Name and Version
          Center(
            child: Text(
              'Flutter Drawing App',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          
          // App Description
          const Text(
            'A simple yet powerful drawing application built with Flutter. Create, save, and share your artwork with ease.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Features
          _buildSectionHeader(context, 'Features'),
          _buildFeatureItem('Multiple drawing tools (pencil, shapes, eraser)'),
          _buildFeatureItem('Color selection and brush size adjustment'),
          _buildFeatureItem('Undo/redo functionality'),
          _buildFeatureItem('Save drawings to gallery'),
          _buildFeatureItem('Share your artwork'),
          _buildFeatureItem('Dark mode support'),
          _buildFeatureItem('Customizable settings'),
          const SizedBox(height: 24),
          
          // How to Use
          _buildSectionHeader(context, 'How to Use'),
          _buildHelpItem(
            '1. Drawing Tools',
            'Select a tool from the toolbar at the bottom of the drawing screen. Available tools include pencil, line, rectangle, circle, and eraser.',
          ),
          _buildHelpItem(
            '2. Colors and Size',
            'Choose a color from the color palette and adjust the brush size using the slider.',
          ),
          _buildHelpItem(
            '3. Saving',
            'Tap the save icon in the app bar to save your drawing. You can give it a name and choose to save it to your device gallery as well.',
          ),
          _buildHelpItem(
            '4. Gallery',
            'View all your saved drawings in the Gallery tab. Tap on a drawing to view it in full screen, share, or delete it.',
          ),
          _buildHelpItem(
            '5. Settings',
            'Customize the app behavior in the Settings tab, including default brush color and size, grid visibility, and theme.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 20, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
  
  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

