import 'dart:io';
import 'package:flutter/material.dart';
import '../models/drawing.dart';
import '../services/drawing_storage.dart';
import 'drawing_screen.dart';

class DrawingDetailsScreen extends StatelessWidget {
  final Drawing drawing;
  
  const DrawingDetailsScreen({Key? key, required this.drawing}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(drawing.name),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.share),
          //   onPressed: () => _shareDrawing(context),
          //   tooltip: 'Share',
          // ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: File(drawing.path).existsSync()
                    ? Image.file(File(drawing.path))
                    : const Center(
                        child: Text('Image not found'),
                      ),
              ),
            ),
            // Bottom action bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    context,
                    icon: Icons.edit,
                    label: 'Edit',
                    onTap: () => _editDrawing(context),
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.share,
                    label: 'Share',
                    onTap: () => _shareDrawing(context),
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.delete,
                    label: 'Delete',
                    onTap: () => _confirmDelete(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
  
  void _editDrawing(BuildContext context) {
    // TODO: Implement editing functionality
    // This would require storing the drawing points data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Editing functionality coming soon!')),
    );
  }
  
  void _shareDrawing(BuildContext context) async {
    try {
      await DrawingStorage.shareDrawing(drawing.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing drawing: $e')),
      );
    }
  }
  
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Drawing'),
        content: const Text('Are you sure you want to delete this drawing? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => _deleteDrawing(context),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
  
  void _deleteDrawing(BuildContext context) async {
    final success = await DrawingStorage.deleteDrawing(drawing.id);
    
    Navigator.pop(context); // Close dialog
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drawing deleted')),
      );
      Navigator.pop(context); // Go back to gallery
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete drawing')),
      );
    }
  }
}

