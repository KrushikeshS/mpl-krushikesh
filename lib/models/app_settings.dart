import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  // Theme settings
  bool _darkMode = false;
  bool get darkMode => _darkMode;
  
  // Drawing settings
  Color _defaultColor = Colors.black;
  double _defaultStrokeWidth = 5.0;
  bool _showGrid = false;
  bool _autosave = true;
  
  // Getters
  Color get defaultColor => _defaultColor;
  double get defaultStrokeWidth => _defaultStrokeWidth;
  bool get showGrid => _showGrid;
  bool get autosave => _autosave;
  
  // Setters with notifications
  void setDarkMode(bool value) {
    _darkMode = value;
    notifyListeners();
  }
  
  void setDefaultColor(Color color) {
    _defaultColor = color;
    notifyListeners();
  }
  
  void setDefaultStrokeWidth(double width) {
    _defaultStrokeWidth = width;
    notifyListeners();
  }
  
  void setShowGrid(bool value) {
    _showGrid = value;
    notifyListeners();
  }
  
  void setAutosave(bool value) {
    _autosave = value;
    notifyListeners();
  }
}

