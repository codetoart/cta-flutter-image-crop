import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import './crop_helper.dart';

class CustomRenderObjectWidget extends SingleChildRenderObjectWidget {
  final Key key;
  final double aspectRatio;
  final Color dimColor;
  final Color backgroundColor;
  final BoxShape shape;

  CustomRenderObjectWidget({
    @required Widget child,
    @required this.aspectRatio,
    this.key,
    this.backgroundColor: Colors.black,
    this.dimColor: const Color.fromRGBO(0, 0, 0, 0.8),
    this.shape,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return CustomRender()
      ..aspectRatio = aspectRatio
      ..dimColor = dimColor
      ..backgroundColor = backgroundColor
      ..shape = shape;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant CustomRender renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    bool needsLayout = false;
    bool needsPaint = false;
    if (renderObject.aspectRatio != aspectRatio) {
      renderObject.aspectRatio = aspectRatio;
      needsLayout = true;
    }

    if (renderObject.shape != shape) {
      renderObject.shape = shape;
      needsPaint = true;
    }

    if (renderObject.dimColor != dimColor) {
      renderObject.dimColor = dimColor;
      needsPaint = true;
    }

    if (renderObject.backgroundColor != backgroundColor) {
      renderObject.backgroundColor = backgroundColor;
      needsPaint = true;
    }

    if (needsLayout) {
      renderObject.markNeedsLayout();
    }
    if (needsPaint) {
      renderObject.markNeedsPaint();
    }
  }
}

class CustomRender extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  double aspectRatio;
  Color dimColor;
  Color backgroundColor;
  BoxShape shape;

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    size = constraints.biggest;

    if (child != null) {
      final forcedSize =
          getSizeToFitByAspectRatio(aspectRatio, size.width, size.height);
      child.layout(BoxConstraints.tight(forcedSize), parentUsesSize: true);
    }
  }

  Path _getDimClipPath() {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final forcedSize =
        getSizeToFitByAspectRatio(aspectRatio, size.width, size.height);
    Rect rect = Rect.fromCenter(
        center: center, width: forcedSize.width, height: forcedSize.height);

    final path = Path();
    if (shape == BoxShape.circle) {
      path.addOval(rect);
    } else if (shape == BoxShape.rectangle) {
      path.addRect(rect);
    }

    path.addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height));
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {}

  @override
  void paint(PaintingContext context, Offset offset) {
    print('paint');
    final bounds = offset & size;

    if (backgroundColor != null) {
      context.canvas.drawRect(bounds, Paint()..color = backgroundColor);
    }

    final forcedSize =
        getSizeToFitByAspectRatio(aspectRatio, size.width, size.height);

    if (child != null) {
      final Offset tmp = (size - forcedSize) as Offset;
      context.paintChild(child, offset + tmp / 2);
  
      final clipPath = _getDimClipPath();

      context.pushClipPath(
        needsCompositing,
        offset,
        bounds,
        clipPath,
        (context, offset) {
          context.canvas.drawRect(bounds, Paint()..color = dimColor);
        },
      );
    }
  }
}
