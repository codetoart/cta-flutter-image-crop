import 'dart:ui' as ui;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import './crop_helper.dart';
import './custom_render_object_widget.dart';

class Cropper extends StatefulWidget {
  final Widget child;
  final CropController cropController;
  final Color faintColor;
  final Widget rectView;
  final BoxShape shape;

  Cropper({
    Key key,
    @required this.child,
    @required this.cropController,
    this.faintColor: const Color.fromRGBO(0, 0, 0, 0.6),
    this.rectView,
    this.shape: BoxShape.rectangle,
  }) : super(key: key);

  @override
  _CropperState createState() => _CropperState();
}

class _CropperState extends State<Cropper> with TickerProviderStateMixin {
  final _key = GlobalKey();
  final _parentKey = GlobalKey();
  final _repaintBoundaryKey = GlobalKey();
  final _repaintBoundaryBoxKey = GlobalKey();

  double _lastScale = 1;
  Offset _lastFocalPoint = Offset.zero;
  Offset _startOffset = Offset.zero;
  Offset _endOffset = Offset.zero;

  AnimationController _controller;
  CurvedAnimation _animation;

  Future<ui.Image> _crop(double pixelRatio) {
    final rrb = _repaintBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary;

    final rrb1 = _repaintBoundaryBoxKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary;

    OffsetLayer offsetLayer = rrb.layer as OffsetLayer;

    final forcedSize = getSizeToFitByAspectRatio(
      rrb1.size.aspectRatio,
      rrb.constraints.biggest.width,
      rrb.constraints.biggest.height,
    );

    final center = Offset(
      rrb.constraints.biggest.width / 2,
      rrb.constraints.biggest.height / 2,
    );
    Rect rect = Rect.fromCenter(
      center: center,
      width: forcedSize.width,
      height: forcedSize.height,
    );
    return offsetLayer.toImage(rect, pixelRatio: pixelRatio);
  }

  @override
  void initState() {
    super.initState();
    widget.cropController._cropCallback = _crop;

    widget.cropController.addListener(_centerImageWithAnimation);

    //apply animation.
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _animation =
        CurvedAnimation(curve: Curves.fastOutSlowIn, parent: _controller);
    _animation.addListener(() {
      if (_animation.isCompleted) {
        _centerImageNoAnimation();
      }
      setState(() {});
    });
  }

  void _updateImage() {
    final sz = _key.currentContext.size;
    final s =
        widget.cropController._scale * widget.cropController._getMinScale();
    final w = sz.width;
    final h = sz.height;
    final canvas = Rect.fromLTWH(0, 0, w, h);
    _startOffset = widget.cropController._offset;
    _endOffset = widget.cropController._offset;
  }

  void _centerImageWithAnimation() {
    _updateImage();

    widget.cropController._offset = _endOffset;

    if (_controller.isCompleted || _controller.isAnimating) {
      _controller.reset();
    }
    _controller.forward();

    setState(() {});
  }

  void _centerImageNoAnimation() {
    _updateImage();

    _startOffset = _endOffset;
    widget.cropController._offset = _endOffset;

    setState(() {});
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    widget.cropController._offset += details.focalPoint - _lastFocalPoint;
    _lastFocalPoint = details.focalPoint;
    widget.cropController._scale = _lastScale * details.scale;
    _startOffset = widget.cropController._offset;
    _endOffset = widget.cropController._offset;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final rotateValue = widget.cropController._rotation / 180.0 * pi;
    final scaleValue =
        widget.cropController._scale * widget.cropController._getMinScale();
    final offsetValue = Offset.lerp(_startOffset, _endOffset, 1.0);

    Widget _buildCanvas() {
      return IgnorePointer(
        key: _key,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(offsetValue.dx, offsetValue.dy, 0)
            ..rotateZ(rotateValue)
            ..scale(scaleValue, scaleValue, 1),
          child: widget.child,
        ),
      );
    } //end

    Widget _buildRepaintBoundary() {
      final repaint = RepaintBoundary(
        key: _repaintBoundaryKey,
        child: _buildCanvas(),
      );

      return repaint;
    } //end

    final gestureDetector = GestureDetector(
      onScaleStart: (details) {
        _lastFocalPoint = details.focalPoint;
        _lastScale = max(widget.cropController._scale, 1);
      },
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: (details) {
        widget.cropController._scale = max(widget.cropController._scale, 1);
        _centerImageWithAnimation();
      },
    );

    List<Widget> stackList = [
      Stack(
        children: [
          _buildRepaintBoundary(),
          Positioned.fill(
            child: CustomRenderObjectWidget(
              aspectRatio: widget.cropController._aspectRatio,
              backgroundColor: Colors.transparent,
              shape: widget.shape,
              faintColor: widget.faintColor,
              child: RepaintBoundary(
                key: _repaintBoundaryBoxKey,
                child: widget.rectView,
              ),
            ),
          ),
        ],
      )
    ];

    stackList.add(gestureDetector);

    return ClipRect(
      key: _parentKey,
      child: Stack(
        fit: StackFit.expand,
        children: stackList,
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
