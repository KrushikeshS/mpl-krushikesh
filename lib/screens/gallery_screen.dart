import 'dart:io';
import 'package:flutter/material.dart';
import '../models/drawing.dart';
import '../services/drawing_storage.dart';
import 'drawing_screen.dart';
import 'drawing_details_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<Drawing> _drawings = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadDrawings();
  }
  
  Future<void> _loadDrawings() async {
    setState(() {
      _isLoading = true;
    });
    
    final drawings = await DrawingStorage.loadDrawings();
    
    setState(() {
      _drawings = drawings;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 2 : (screenWidth < 900 ? 3 : 4);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Drawings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDrawings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _drawings.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No drawings yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create your first drawing by tapping the Draw tab below',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDrawings,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _drawings.length,
                    itemBuilder: (context, index) {
                      final drawing = _drawings[index];
                      return _buildDrawingTile(drawing);
                    },
                  ),
                ),
    );
  }
  
  Widget _buildDrawingTile(Drawing drawing) {
    return GestureDetector(
      onTap: () => _openDrawingDetails(drawing),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  drawing.thumbnailPath != null && File(drawing.thumbnailPath!).existsSync()
                      ? Image.file(
                          File(drawing.thumbnailPath!),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, size: 50),
                        ),
                  // Quick action buttons
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // IconButton(
                          //   icon: const Icon(Icons.share, color: Colors.white, size: 20),
                          //   onPressed: () => _shareDrawing(drawing),
                          //   tooltip: 'Share',
                          //   padding: const EdgeInsets.all(8),
                          //   constraints: const BoxConstraints(),
                          // ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                            onPressed: () => _confirmDelete(drawing),
                            tooltip: 'Delete',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drawing.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatDate(drawing.createdAt),
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
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _openDrawingDetails(Drawing drawing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrawingDetailsScreen(drawing: drawing),
      ),
    ).then((_) => _loadDrawings());
  }
  
  void _shareDrawing(Drawing drawing) async {
    try {
      await DrawingStorage.shareDrawing(drawing.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing drawing: $e')),
      );
    }
  }
  
  void _confirmDelete(Drawing drawing) {
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
            onPressed: () => _deleteDrawing(drawing),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
  
  void _deleteDrawing(Drawing drawing) async {
    final success = await DrawingStorage.deleteDrawing(drawing.id);
    
    Navigator.pop(context); // Close dialog
    
    if (success) {
      setState(() {
        _drawings.removeWhere((d) => d.id == drawing.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drawing deleted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete drawing')),
      );
    }
  }
}

