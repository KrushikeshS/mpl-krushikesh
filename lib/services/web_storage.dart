import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'package:uuid/uuid.dart';
import '../models/drawing.dart';

class WebStorage {
  static const String _drawingsKey = 'web_drawings';
  static const String _drawingsDataKey = 'web_drawings_data';
  static final uuid = Uuid();

  // Check if running on web
  static bool get isWeb => kIsWeb;

  // Download drawing to system (for web)
  static void downloadDrawing(Uint8List bytes, String fileName) {
    if (!isWeb) return;

    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', '$fileName.png')
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();

    // Clean up
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  // Save drawing to browser storage
  static Future<Drawing?> saveDrawingToLocalStorage(
    Uint8List bytes,
    String name,
  ) async {
    if (!isWeb) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final id = uuid.v4();
      final now = DateTime.now();

      // Convert image to base64 for storage
      final base64Image = base64Encode(bytes);

      // Create drawing object
      final drawing = Drawing(
        id: id,
        name:
            name.isEmpty ? 'Drawing ${now.toString().substring(0, 16)}' : name,
        path: id, // Use ID as path reference
        createdAt: now,
      );

      // Get existing drawings list
      final List<Drawing> drawings = await loadDrawingsFromLocalStorage();
      drawings.add(drawing);

      // Save drawings list
      final jsonList = drawings.map((d) => d.toJson()).toList();
      await prefs.setString(_drawingsKey, json.encode(jsonList));

      // Save drawing data separately (to avoid size limits)
      await prefs.setString('$_drawingsDataKey:$id', base64Image);

      return drawing;
    } catch (e) {
      print('Error saving drawing to local storage: $e');
      return null;
    }
  }

  // Load drawings from browser storage
  static Future<List<Drawing>> loadDrawingsFromLocalStorage() async {
    if (!isWeb) return [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final drawingsJson = prefs.getString(_drawingsKey);

      if (drawingsJson == null) return [];

      final List<dynamic> jsonList = json.decode(drawingsJson);
      return jsonList.map((json) => Drawing.fromJson(json)).toList();
    } catch (e) {
      print('Error loading drawings from local storage: $e');
      return [];
    }
  }

  // Load drawing data from browser storage
  static Future<Uint8List?> loadDrawingDataFromLocalStorage(String id) async {
    if (!isWeb) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final base64Image = prefs.getString('$_drawingsDataKey:$id');

      if (base64Image == null) return null;

      return base64Decode(base64Image);
    } catch (e) {
      print('Error loading drawing data from local storage: $e');
      return null;
    }
  }

  // Delete drawing from browser storage
  static Future<bool> deleteDrawingFromLocalStorage(String id) async {
    if (!isWeb) return false;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove drawing data
      await prefs.remove('$_drawingsDataKey:$id');

      // Update drawings list
      final drawings = await loadDrawingsFromLocalStorage();
      drawings.removeWhere((d) => d.id == id);

      final jsonList = drawings.map((d) => d.toJson()).toList();
      await prefs.setString(_drawingsKey, json.encode(jsonList));

      return true;
    } catch (e) {
      print('Error deleting drawing from local storage: $e');
      return false;
    }
  }
}
