import 'package:flutter/material.dart';

class ComfortProvider extends ChangeNotifier {
  bool _isEnabled = false;

  bool get isEnabled => _isEnabled;

  void enable() {
    _isEnabled = true;
    notifyListeners();
  }

  void disable() {
    _isEnabled = false;
    notifyListeners();
  }
}
