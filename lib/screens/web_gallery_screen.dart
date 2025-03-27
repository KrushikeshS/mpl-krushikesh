import 'package:flutter/material.dart';
import '../models/drawing.dart';
import '../services/web_storage.dart';
import 'dart:typed_data';

class WebGalleryScreen extends StatefulWidget {
  const WebGalleryScreen({Key? key}) : super(key: key);

  @override
  _WebGalleryScreenState createState() => _WebGalleryScreenState();
}

class _WebGalleryScreenState extends State<WebGalleryScreen> {
  List<Drawing> _drawings = [];
  Map<String, Uint8List?> _thumbnails = {};
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

    final drawings = await WebStorage.loadDrawingsFromLocalStorage();

    // Load thumbnails for each drawing
    Map<String, Uint8List?> thumbnails = {};
    for (var drawing in drawings) {
      thumbnails[drawing.id] =
          await WebStorage.loadDrawingDataFromLocalStorage(drawing.id);
    }

    setState(() {
      _drawings = drawings;
      _thumbnails = thumbnails;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 2 : (screenWidth < 900 ? 3 : 4);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Drawings'),
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
                          'No drawings saved in device',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Save a drawing to  to see it here',
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
    final thumbnail = _thumbnails[drawing.id];

    return GestureDetector(
      onTap: () => _viewDrawing(drawing),
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
                  thumbnail != null
                      ? Image.memory(
                          thumbnail,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey[300],
                          child:
                              const Icon(Icons.image_not_supported, size: 50),
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
                          IconButton(
                            icon: const Icon(Icons.download,
                                color: Colors.white, size: 20),
                            onPressed: () => _downloadDrawing(drawing),
                            tooltip: 'Download',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.white, size: 20),
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

  void _viewDrawing(Drawing drawing) async {
    final imageData =
        await WebStorage.loadDrawingDataFromLocalStorage(drawing.id);
    if (imageData != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(drawing.name),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.memory(imageData),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                      onPressed: () {
                        WebStorage.downloadDrawing(imageData, drawing.name);
                        Navigator.pop(context);
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(drawing);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _downloadDrawing(Drawing drawing) async {
    final imageData =
        await WebStorage.loadDrawingDataFromLocalStorage(drawing.id);
    if (imageData != null) {
      WebStorage.downloadDrawing(imageData, drawing.name);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drawing downloaded')),
      );
    }
  }

  void _confirmDelete(Drawing drawing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Drawing'),
        content: const Text(
            'Are you sure you want to delete this drawing from browser storage? This action cannot be undone.'),
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
    final success = await WebStorage.deleteDrawingFromLocalStorage(drawing.id);

    Navigator.pop(context); // Close dialog

    if (success) {
      setState(() {
        _drawings.removeWhere((d) => d.id == drawing.id);
        _thumbnails.remove(drawing.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drawing deleted from browser storage')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete drawing')),
      );
    }
  }
}
