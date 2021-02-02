import 'dart:ui' as ui;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import './crop_helper.dart';
import './custom_render_object_widget.dart';
import './state_info.dart';

class Cropper extends StatefulWidget {
  final Widget child;
  final CropController cropController;
  final Color backgroundColor;
  final Color dimColor;
  final Widget helper;
  final BoxShape shape;
  final ValueChanged<StateInfo> onChangedInfo;

  Cropper({
    Key key,
    @required this.child,
    @required this.cropController,
    this.dimColor: const Color.fromRGBO(0, 0, 0, 0.8),
    this.backgroundColor: Colors.white,
    this.helper,
    this.shape: BoxShape.rectangle,
    this.onChangedInfo,
  }) : super(key: key);

  @override
  _CropperState createState() => _CropperState();
}

class _CropperState extends State<Cropper> with TickerProviderStateMixin {
  final _key = GlobalKey();
  final _parentKey = GlobalKey();
  final _repaintBoundaryKey = GlobalKey();

  double _previousScale = 1;
  Offset _previousOffset = Offset.zero;
  Offset _startOffset = Offset.zero;
  Offset _endOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    print('initstate crop widget');
  }

  @override
  Widget build(BuildContext context) {
    print('build crop widget');
    final r = widget.cropController._rotation / 180.0 * pi;
    final s =
        widget.cropController._scale * widget.cropController._getMinScale();
    final o = Offset.lerp(_startOffset, _endOffset, 1.0);

    Widget _buildInnerCanvas() {
      print('_buildInnerCanvas');
      final ip = IgnorePointer(
        key: _key,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(o.dx, o.dy, 0)
            ..rotateZ(r)
            ..scale(s, s, 1),
          child: FittedBox(
            child: widget.child,
            fit: BoxFit.cover,
          ),
        ),
      );

      return ip;
    } //end

    Widget _buildRepaintBoundary() {
      print('_buildRepaintBoundary');
      final repaint = RepaintBoundary(
        key: _repaintBoundaryKey,
        child: _buildInnerCanvas(),
      );

      if (widget.helper == null) {
        return repaint;
      }

      return Stack(
        fit: StackFit.expand,
        children: [repaint, widget.helper],
      );
    } //end

    List<Widget> over = [
      CustomRenderObjectWidget(
        aspectRatio: widget.cropController._aspectRatio,
        backgroundColor: widget.backgroundColor,
        dimColor: widget.dimColor,
        shape: widget.shape,
        child: _buildRepaintBoundary(),
      ),
    ];

    return ClipRect(
      key: _parentKey,
      child: Stack(
        fit: StackFit.expand,
        children: over,
      ),
    );
  }
}

typedef _CropCallback = Future<ui.Image> Function(double pixelRatio);

class CropController extends ChangeNotifier {
  double _aspectRatio = 1;
  double _rotation = 0;
  double _scale = 1;
  Offset _offset = Offset.zero;
  _CropCallback _cropCallback;

  double get aspectRatio => _aspectRatio;
  set aspectRatio(double value) {
    _aspectRatio = value;
    notifyListeners();
  }

  double get scale => max(_scale, 1);
  set scale(double value) {
    _scale = max(value, 1);
    notifyListeners();
  }

  double get rotation => _rotation;
  set rotation(double value) {
    _rotation = value;
    notifyListeners();
  }

  Offset get offset => _offset;
  set offset(Offset value) {
    _offset = value;
    notifyListeners();
  }

  Matrix4 get transform => Matrix4.identity()
    ..translate(_offset.dx, _offset.dy, 0)
    ..rotateZ(_rotation)
    ..scale(_scale, _scale, 1);

  CropController({
    double aspectRatio: 1.0,
    double scale: 1.0,
    double rotation: 0,
  }) {
    _aspectRatio = aspectRatio;
    _scale = scale;
    _rotation = rotation;
  }

  double _getMinScale() {
    final r = (_rotation % 360) / 180.0 * pi;
    final rabs = r.abs();

    final sinr = sin(rabs).abs();
    final cosr = cos(rabs).abs();

    final x = cosr * _aspectRatio + sinr;
    final y = sinr * _aspectRatio + cosr;

    final m = max(x / _aspectRatio, y);

    return m;
  }

  Future<ui.Image> crop({double pixelRatio: 1}) {
    if (_cropCallback == null) {
      return Future.value(null);
    }

    return _cropCallback.call(pixelRatio);
  }
}
