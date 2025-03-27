import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/drawing.dart';
import '../services/drawing_storage.dart';
import '../services/web_storage.dart';
import '../widgets/color_picker.dart';
import '../widgets/save_dialog.dart';
import '../widgets/web_save_dialog.dart';

class DrawingScreen extends StatefulWidget {
  final Drawing? existingDrawing;

  const DrawingScreen({Key? key, this.existingDrawing}) : super(key: key);

  @override
  _DrawingScreenState createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  late Color selectedColor;
  late double strokeWidth;
  List<DrawingPoint?> points = [];
  List<List<DrawingPoint?>> undoHistory = [];
  List<List<DrawingPoint?>> redoHistory = [];
  DrawingMode drawingMode = DrawingMode.freeStyle;
  Offset? startPoint;
  Offset? endPoint;
  bool _isGridVisible = false;
  bool _showToolOptions = false;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<AppSettings>(context, listen: false);
    selectedColor = settings.defaultColor;
    strokeWidth = settings.defaultStrokeWidth;
    _isGridVisible = settings.showGrid;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing Canvas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _showSaveDialog,
            tooltip: 'Save Drawing',
          ),
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadDrawing,
              tooltip: 'Download Drawing',
            ),
          // IconButton(
          //   icon: const Icon(Icons.share),
          //   onPressed: _shareDrawing,
          //   tooltip: 'Share Drawing',
          // ),
        ],
      ),
      body: Stack(
        children: [
          // Background grid (if enabled)
          if (_isGridVisible)
            CustomPaint(
              painter: GridPainter(),
              size: Size.infinite,
            ),

          // Drawing Canvas
          GestureDetector(
            onPanStart: (details) {
              setState(() {
                startPoint = details.localPosition;
                if (drawingMode == DrawingMode.freeStyle) {
                  redoHistory = [];
                  undoHistory.add(List.from(points));
                  points.add(
                    DrawingPoint(
                      details.localPosition,
                      Paint()
                        ..color = selectedColor
                        ..strokeWidth = strokeWidth
                        ..strokeCap = StrokeCap.round,
                    ),
                  );
                }
              });
            },
            onPanUpdate: (details) {
              setState(() {
                endPoint = details.localPosition;
                if (drawingMode == DrawingMode.freeStyle) {
                  points.add(
                    DrawingPoint(
                      details.localPosition,
                      Paint()
                        ..color = selectedColor
                        ..strokeWidth = strokeWidth
                        ..strokeCap = StrokeCap.round,
                    ),
                  );
                }
              });
            },
            onPanEnd: (details) {
              setState(() {
                if (drawingMode != DrawingMode.freeStyle &&
                    startPoint != null &&
                    endPoint != null) {
                  redoHistory = [];
                  undoHistory.add(List.from(points));

                  if (drawingMode == DrawingMode.line) {
                    points.add(
                      DrawingPoint(
                        startPoint!,
                        Paint()
                          ..color = selectedColor
                          ..strokeWidth = strokeWidth
                          ..strokeCap = StrokeCap.round,
                        endPoint: endPoint,
                        mode: drawingMode,
                      ),
                    );
                  } else if (drawingMode == DrawingMode.rectangle ||
                      drawingMode == DrawingMode.circle) {
                    points.add(
                      DrawingPoint(
                        startPoint!,
                        Paint()
                          ..color = selectedColor
                          ..strokeWidth = strokeWidth
                          ..style = PaintingStyle.stroke
                          ..strokeCap = StrokeCap.round,
                        endPoint: endPoint,
                        mode: drawingMode,
                      ),
                    );
                  }
                }

                startPoint = null;
                endPoint = null;
                points.add(null); // Add null to indicate end of a stroke
              });
            },
            child: CustomPaint(
              painter: DrawingPainter(
                points: points,
                previewStartPoint: startPoint,
                previewEndPoint: endPoint,
                previewMode: drawingMode,
                previewPaint: Paint()
                  ..color = selectedColor
                  ..strokeWidth = strokeWidth
                  ..style = PaintingStyle.stroke
                  ..strokeCap = StrokeCap.round,
              ),
              size: Size.infinite,
            ),
          ),

          // Mobile-friendly Bottom Toolbar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary Tools Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildToolButton(
                            Icons.edit, DrawingMode.freeStyle, 'Pencil',
                            size: 28),
                        _buildToolButton(
                            Icons.horizontal_rule, DrawingMode.line, 'Line',
                            size: 28),
                        _buildToolButton(Icons.rectangle_outlined,
                            DrawingMode.rectangle, 'Rectangle',
                            size: 28),
                        _buildToolButton(
                            Icons.circle_outlined, DrawingMode.circle, 'Circle',
                            size: 28),
                        _buildToolButton(
                            Icons.auto_fix_high, DrawingMode.eraser, 'Eraser',
                            size: 28),
                        IconButton(
                          icon: Icon(
                              _showToolOptions
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 28),
                          onPressed: () {
                            setState(() {
                              _showToolOptions = !_showToolOptions;
                            });
                          },
                          tooltip: _showToolOptions
                              ? 'Hide Options'
                              : 'Show Options',
                        ),
                      ],
                    ),
                  ),

                  // Secondary Tools (expandable)
                  if (_showToolOptions)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),

                          // Action buttons
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.grid_on, size: 28),
                                  onPressed: _toggleGrid,
                                  tooltip: 'Toggle Grid',
                                  color: _isGridVisible
                                      ? Theme.of(context).primaryColor
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.undo, size: 28),
                                  onPressed: _undo,
                                  tooltip: 'Undo',
                                  color:
                                      undoHistory.isEmpty ? Colors.grey : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.redo, size: 28),
                                  onPressed: _redo,
                                  tooltip: 'Redo',
                                  color:
                                      redoHistory.isEmpty ? Colors.grey : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 28),
                                  onPressed: _clearCanvas,
                                  tooltip: 'Clear All',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Color Picker (scrollable)
                          SizedBox(
                            height: 50,
                            child: ColorPicker(
                              selectedColor: selectedColor,
                              onColorSelected: (color) {
                                setState(() {
                                  selectedColor = color;
                                  if (drawingMode == DrawingMode.eraser) {
                                    drawingMode = DrawingMode.freeStyle;
                                  }
                                });
                              },
                              showLabel: false,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Stroke Width Slider
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                const Icon(Icons.line_weight, size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Slider(
                                    value: strokeWidth,
                                    min: 1.0,
                                    max: 20.0,
                                    divisions: 19,
                                    onChanged: (value) {
                                      setState(() {
                                        strokeWidth = value;
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '${strokeWidth.toInt()}px',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, DrawingMode mode, String tooltip,
      {double size = 24}) {
    final isSelected = drawingMode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () {
          setState(() {
            drawingMode = mode;
            if (mode == DrawingMode.eraser) {
              selectedColor = Colors.white;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(
            icon,
            size: size,
            color: isSelected ? Theme.of(context).primaryColor : null,
          ),
        ),
      ),
    );
  }

  void _undo() {
    if (undoHistory.isNotEmpty) {
      setState(() {
        redoHistory.add(List.from(points));
        points = List.from(undoHistory.last);
        undoHistory.removeLast();
      });
    }
  }

  void _redo() {
    if (redoHistory.isNotEmpty) {
      setState(() {
        undoHistory.add(List.from(points));
        points = List.from(redoHistory.last);
        redoHistory.removeLast();
      });
    }
  }

  void _clearCanvas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Canvas'),
        content:
            const Text('Are you sure you want to clear the entire drawing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                undoHistory.add(List.from(points));
                redoHistory = [];
                points = [];
              });
            },
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
  }

  void _toggleGrid() {
    setState(() {
      _isGridVisible = !_isGridVisible;
    });

    // Also update in settings if user wants to keep this preference
    final settings = Provider.of<AppSettings>(context, listen: false);
    settings.setShowGrid(_isGridVisible);
  }

  Future<void> _showSaveDialog() async {
    if (kIsWeb) {
      // Use web-specific save dialog
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => const WebSaveDialog(),
      );

      if (result != null) {
        await _saveDrawingWeb(result['name'], result['saveToLocalStorage']);
      }
    } else {
      // Use mobile save dialog
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => const SaveDialog(),
      );

      if (result != null) {
        await _saveDrawing(result['name'], result['saveToGallery']);
      }
    }
  }

  Future<void> _saveDrawing(String name, bool saveToGallery) async {
    try {
      // Create a recorder and canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Get the size of the screen
      final size = MediaQuery.of(context).size;

      // Draw the background (white or transparent)
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );

      // Draw all the points
      final painter = DrawingPainter(points: points);
      painter.paint(canvas, size);

      // Convert to image
      final picture = recorder.endRecording();
      final img =
          await picture.toImage(size.width.toInt(), size.height.toInt());

      // Save the drawing
      final drawing = await DrawingStorage.saveDrawing(img, name,
          saveToGallery: saveToGallery);

      if (drawing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Drawing saved as "${drawing.name}"')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save drawing')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving drawing: $e')),
      );
    }
  }

  Future<void> _saveDrawingWeb(String name, bool saveToLocalStorage) async {
    try {
      // Create a recorder and canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = MediaQuery.of(context).size;

      // Draw white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );

      // Draw all the points
      final painter = DrawingPainter(points: points);
      painter.paint(canvas, size);

      // Convert to image
      final picture = recorder.endRecording();
      final img =
          await picture.toImage(size.width.toInt(), size.height.toInt());
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

      if (pngBytes != null) {
        final bytes = pngBytes.buffer.asUint8List();

        // Save to local storage if requested
        if (saveToLocalStorage) {
          final drawing =
              await WebStorage.saveDrawingToLocalStorage(bytes, name);
          if (drawing != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Drawing saved to browser storage as "${drawing.name}"')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Failed to save drawing to browser storage')),
            );
          }
        } else {
          // Download the file
          WebStorage.downloadDrawing(bytes, name.isEmpty ? 'drawing' : name);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Drawing downloaded')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving drawing: $e')),
      );
    }
  }

  Future<void> _downloadDrawing() async {
    if (!kIsWeb) return;

    try {
      // Create a recorder and canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = MediaQuery.of(context).size;

      // Draw white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );

      // Draw all the points
      final painter = DrawingPainter(points: points);
      painter.paint(canvas, size);

      // Convert to image
      final picture = recorder.endRecording();
      final img =
          await picture.toImage(size.width.toInt(), size.height.toInt());
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

      if (pngBytes != null) {
        final bytes = pngBytes.buffer.asUint8List();
        WebStorage.downloadDrawing(bytes, 'drawing');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drawing downloaded')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading drawing: $e')),
      );
    }
  }

  Future<void> _shareDrawing() async {
    try {
      // Create a temporary image to share
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = MediaQuery.of(context).size;

      // Draw white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );

      // Draw all the points
      final painter = DrawingPainter(points: points);
      painter.paint(canvas, size);

      // Convert to image
      final picture = recorder.endRecording();
      final img =
          await picture.toImage(size.width.toInt(), size.height.toInt());
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

      if (pngBytes != null) {
        // Save to temporary file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_drawing.png');
        await tempFile.writeAsBytes(pngBytes.buffer.asUint8List());

        // Share the file
        await DrawingStorage.shareDrawing(tempFile.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing drawing: $e')),
      );
    }
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;
  final Offset? previewStartPoint;
  final Offset? previewEndPoint;
  final DrawingMode? previewMode;
  final Paint? previewPaint;

  DrawingPainter({
    required this.points,
    this.previewStartPoint,
    this.previewEndPoint,
    this.previewMode,
    this.previewPaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        // For free-style drawing
        canvas.drawLine(
            points[i]!.offset, points[i + 1]!.offset, points[i]!.paint);
      } else if (points[i] != null && points[i]!.endPoint != null) {
        // For shapes
        _drawShape(canvas, points[i]!);
      }
    }

    // Draw the last point
    if (points.isNotEmpty &&
        points.last != null &&
        points.last!.endPoint != null) {
      _drawShape(canvas, points.last!);
    }

    // Draw preview of current shape being drawn
    if (previewStartPoint != null &&
        previewEndPoint != null &&
        previewPaint != null &&
        previewMode != null &&
        previewMode != DrawingMode.freeStyle) {
      final previewPoint = DrawingPoint(
        previewStartPoint!,
        previewPaint!,
        endPoint: previewEndPoint,
        mode: previewMode,
      );
      _drawShape(canvas, previewPoint);
    }
  }

  void _drawShape(Canvas canvas, DrawingPoint point) {
    switch (point.mode) {
      case DrawingMode.line:
        canvas.drawLine(point.offset, point.endPoint!, point.paint);
        break;
      case DrawingMode.rectangle:
        final rect = Rect.fromPoints(point.offset, point.endPoint!);
        canvas.drawRect(rect, point.paint);
        break;
      case DrawingMode.circle:
        final center = Offset(
          (point.offset.dx + point.endPoint!.dx) / 2,
          (point.offset.dy + point.endPoint!.dy) / 2,
        );
        final radius = (point.offset - point.endPoint!).distance / 2;
        canvas.drawCircle(center, radius, point.paint);
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.previewStartPoint != previewStartPoint ||
        oldDelegate.previewEndPoint != previewEndPoint;
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    const gridSize = 20.0;

    // Draw vertical lines
    for (double i = 0; i <= size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i <= size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
