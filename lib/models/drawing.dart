import 'dart:ui';
import 'package:flutter/material.dart';

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

class Drawing {
  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final String? thumbnailPath;
  
  Drawing({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    this.thumbnailPath,
  });
  
  factory Drawing.fromJson(Map<String, dynamic> json) {
    return Drawing(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      createdAt: DateTime.parse(json['createdAt']),
      thumbnailPath: json['thumbnailPath'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'createdAt': createdAt.toIso8601String(),
      'thumbnailPath': thumbnailPath,
    };
  }
}

