import 'dart:ui';
import 'package:flutter/material.dart';

class StateInfo {
  final double rotation;
  final double scale;
  final Offset translation;

  StateInfo({
    @required this.rotation,
    @required this.scale,
    @required this.translation,
  });
}
