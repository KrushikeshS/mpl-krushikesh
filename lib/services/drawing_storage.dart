import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/drawing.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';

class DrawingStorage {
  static const String _drawingsFileName = 'drawings.json';
  static final uuid = Uuid();
  
  // Get the directory for storing drawings
  static Future<Directory> get _drawingsDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final drawingsDir = Directory('${appDir.path}/drawings');
    if (!await drawingsDir.exists()) {
      await drawingsDir.create(recursive: true);
    }
    return drawingsDir;
  }
  
  // Get the file that stores the list of drawings
  static Future<File> get _drawingsFile async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/$_drawingsFileName');
  }
  
  // Load all drawings
  static Future<List<Drawing>> loadDrawings() async {
    try {
      final file = await _drawingsFile;
      if (!await file.exists()) {
        return [];
      }
      
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList.map((json) => Drawing.fromJson(json)).toList();
    } catch (e) {
      print('Error loading drawings: $e');
      return [];
    }
  }
  
  // Save the list of drawings
  static Future<void> _saveDrawingsList(List<Drawing> drawings) async {
    try {
      final file = await _drawingsFile;
      final jsonList = drawings.map((drawing) => drawing.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Error saving drawings list: $e');
    }
  }
  
  // Save a drawing to storage and add it to the list
  static Future<Drawing?> saveDrawing(
    ui.Image image, 
    String name, 
    {bool saveToGallery = false}
  ) async {
    try {
      final drawingsDir = await _drawingsDirectory;
      final id = uuid.v4();
      final now = DateTime.now();
      final fileName = '${now.millisecondsSinceEpoch}.png';
      final thumbnailName = '${now.millisecondsSinceEpoch}_thumb.png';
      
      // Save full image
      final pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (pngBytes == null) return null;
      
      final buffer = pngBytes.buffer.asUint8List();
      final imagePath = '${drawingsDir.path}/$fileName';
      await File(imagePath).writeAsBytes(buffer);
      
      // Create and save thumbnail
      final thumbnailImage = await _createThumbnail(image);
      final thumbnailBytes = await thumbnailImage.toByteData(format: ui.ImageByteFormat.png);
      if (thumbnailBytes == null) return null;
      
      final thumbnailBuffer = thumbnailBytes.buffer.asUint8List();
      final thumbnailPath = '${drawingsDir.path}/$thumbnailName';
      await File(thumbnailPath).writeAsBytes(thumbnailBuffer);
      
      // Save to gallery if requested
      if (saveToGallery) {
        try {
          final result = await ImageGallerySaver.saveImage(
            buffer,
            quality: 100,
            name: name.isEmpty ? 'Drawing_${now.millisecondsSinceEpoch}' : name
          );
          print("Gallery save result: $result");
        } catch (e) {
          print("Error saving to gallery: $e");
          // Continue even if gallery save fails
        }
      }
      
      // Create drawing object
      final drawing = Drawing(
        id: id,
        name: name.isEmpty ? 'Drawing ${now.toString().substring(0, 16)}' : name,
        path: imagePath,
        createdAt: now,
        thumbnailPath: thumbnailPath,
      );
      
      // Add to list and save
      final drawings = await loadDrawings();
      drawings.add(drawing);
      await _saveDrawingsList(drawings);
      
      return drawing;
    } catch (e) {
      print('Error saving drawing: $e');
      return null;
    }
  }
  
  // Create a thumbnail from an image
  static Future<ui.Image> _createThumbnail(ui.Image image) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(100, 100);
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    
    canvas.drawImageRect(image, src, dst, Paint());
    
    final picture = recorder.endRecording();
    return picture.toImage(size.width.toInt(), size.height.toInt());
  }
  
  // Delete a drawing
  static Future<bool> deleteDrawing(String id) async {
    try {
      final drawings = await loadDrawings();
      final drawingIndex = drawings.indexWhere((d) => d.id == id);
      
      if (drawingIndex >= 0) {
        final drawing = drawings[drawingIndex];
        
        // Delete the image file
        final imageFile = File(drawing.path);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
        
        // Delete the thumbnail file
        if (drawing.thumbnailPath != null) {
          final thumbnailFile = File(drawing.thumbnailPath!);
          if (await thumbnailFile.exists()) {
            await thumbnailFile.delete();
          }
        }
        
        // Remove from list and save
        drawings.removeAt(drawingIndex);
        await _saveDrawingsList(drawings);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting drawing: $e');
      return false;
    }
  }
  
  // Share a drawing
  static Future<void> shareDrawing(String path) async {
    try {
      await Share.shareFiles([path], text: 'Check out my drawing!');
    } catch (e) {
      print('Error sharing drawing: $e');
    }
  }
  
  // Load a drawing's image
  static Future<Uint8List?> loadDrawingImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error loading drawing image: $e');
      return null;
    }
  }
}

