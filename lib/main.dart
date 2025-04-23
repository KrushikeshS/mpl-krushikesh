import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_drawing_app/screens/login_screen.dart';
import 'package:flutter_drawing_app/screens/signup_screen.dart';
import 'screens/drawing_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/web_gallery_screen.dart';
import 'models/app_settings.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyD9S7CtVpgsjmhQifS4BPmZsA_lugrX-BA",
          authDomain: "mplkrushikesh-283a2.firebaseapp.com",
          projectId: "mplkrushikesh-283a2",
          storageBucket: "mplkrushikesh-283a2.firebasestorage.app",
          messagingSenderId: "254953847733",
          appId: "1:254953847733:web:9fc02cbe881102f296f7fc"));
  // runApp(MyApp());
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppSettings(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Drawing App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
      },
      // home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late List<Widget> _screens;
  late List<NavigationDestination> _destinations;

  @override
  void initState() {
    super.initState();

    // Set up screens and navigation based on platform
    if (kIsWeb) {
      _screens = [
        const DrawingScreen(),
        // const GalleryScreen(),
        const WebGalleryScreen(), // Web-specific gallery for browser storage
        const SettingsScreen(),
        const AboutScreen(),
      ];

      _destinations = const [
        NavigationDestination(
          icon: Icon(Icons.edit),
          label: 'Draw',
        ),
        // NavigationDestination(
        //   icon: Icon(Icons.photo_library),
        //   label: 'Gallery',
        // ),
        NavigationDestination(
          icon: Icon(Icons.storage),
          label: 'Gallery',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
        NavigationDestination(
          icon: Icon(Icons.help_outline),
          label: 'About',
        ),
      ];
    } else {
      _screens = [
        const DrawingScreen(),
        // const GalleryScreen(),
        const SettingsScreen(),
        const AboutScreen(),
      ];

      _destinations = const [
        NavigationDestination(
          icon: Icon(Icons.edit),
          label: 'Draw',
        ),
        // NavigationDestination(
        //   icon: Icon(Icons.photo_library),
        //   label: 'Gallery',
        // ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
        NavigationDestination(
          icon: Icon(Icons.help_outline),
          label: 'About',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        height: 65, // More compact for mobile
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: _destinations,
      ),
    );
  }
}

class DrawingPage extends StatefulWidget {
  const DrawingPage({Key? key}) : super(key: key);

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  Color selectedColor = Colors.black;
  double strokeWidth = 5.0;
  List<DrawingPoint?> points = [];
  List<List<DrawingPoint?>> undoHistory = [];
  List<List<DrawingPoint?>> redoHistory = [];
  DrawingMode drawingMode = DrawingMode.freeStyle;
  Offset? startPoint;
  Offset? endPoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDrawing,
            tooltip: 'Save Drawing',
          ),
        ],
      ),
      body: Stack(
        children: [
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

          // Bottom Toolbar
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
                  // Drawing Tools
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildToolButton(
                          Icons.edit, DrawingMode.freeStyle, 'Pencil'),
                      _buildToolButton(
                          Icons.horizontal_rule, DrawingMode.line, 'Line'),
                      _buildToolButton(Icons.rectangle_outlined,
                          DrawingMode.rectangle, 'Rectangle'),
                      _buildToolButton(
                          Icons.circle_outlined, DrawingMode.circle, 'Circle'),
                      _buildToolButton(
                          Icons.auto_fix_high, DrawingMode.eraser, 'Eraser'),
                      IconButton(
                        icon: const Icon(Icons.undo),
                        onPressed: _undo,
                        tooltip: 'Undo',
                        color: undoHistory.isEmpty ? Colors.grey : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.redo),
                        onPressed: _redo,
                        tooltip: 'Redo',
                        color: redoHistory.isEmpty ? Colors.grey : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _clearCanvas,
                        tooltip: 'Clear All',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Color and Stroke Width Controls
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      // Color Picker
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (Color color in [
                                Colors.black,
                                Colors.red,
                                Colors.orange,
                                Colors.yellow,
                                Colors.green,
                                Colors.blue,
                                Colors.indigo,
                                Colors.purple,
                                Colors.pink,
                                Colors.brown,
                                Colors.grey,
                                Colors.white,
                              ])
                                _buildColorButton(color),
                            ],
                          ),
                        ),
                      ),

                      // Stroke Width Slider
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            const Icon(Icons.line_weight, size: 16),
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
                            Text('${strokeWidth.toInt()}px'),
                            const SizedBox(width: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, DrawingMode mode, String tooltip) {
    return IconButton(
      icon: Icon(icon),
      onPressed: () {
        setState(() {
          drawingMode = mode;
          if (mode == DrawingMode.eraser) {
            selectedColor = Colors.white;
          }
        });
      },
      tooltip: tooltip,
      color: drawingMode == mode ? Theme.of(context).primaryColor : null,
    );
  }

  Widget _buildColorButton(Color color) {
    bool isSelected = selectedColor.value == color.value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
          if (drawingMode == DrawingMode.eraser) {
            drawingMode = DrawingMode.freeStyle;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                blurRadius: 5,
              ),
          ],
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
    setState(() {
      undoHistory.add(List.from(points));
      redoHistory = [];
      points = [];
    });
  }

  Future<void> _saveDrawing() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final painter = DrawingPainter(points: points);

      // Get the size of the screen
      final size = MediaQuery.of(context).size;
      painter.paint(canvas, size);

      final picture = recorder.endRecording();
      final img =
          await picture.toImage(size.width.toInt(), size.height.toInt());
      final pngBytes = await img.toByteData(format: ImageByteFormat.png);

      if (pngBytes != null) {
        final buffer = pngBytes.buffer.asUint8List();
        final result = await ImageGallerySaver.saveImage(buffer);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['isSuccess']
                  ? 'Drawing saved to gallery!'
                  : 'Failed to save drawing')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving drawing: $e')),
      );
    }
  }
}

enum DrawingMode {
  freeStyle,
  line,
  rectangle,
  circle,
  eraser,
}

class DrawingPoint {
  final Offset offset;
  final Paint paint;
  final Offset? endPoint;
  final DrawingMode? mode;

  DrawingPoint(this.offset, this.paint, {this.endPoint, this.mode});
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
