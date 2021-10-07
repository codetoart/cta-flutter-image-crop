part of image_cropper;

const dotTotalSize = 32.0; // fixed corner dot size.

typedef CornerDotBuilder = Widget Function(double size, int cornerIndex);

/// Widget for the entry point of crop_your_image.
class Crop extends StatelessWidget {
  /// original image data
  final Uint8List image;

  /// flag if cropping image with circle shape.
  /// if [true], [aspectRatio] is fixed to 1.
  final bool withCircleUi = false;

  /// conroller for control crop actions
  final CropController? controller;

  const Crop({
    Key? key,
    required this.image,
    this.controller,
  })  : 
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (c, constraints) {
        final newData = MediaQuery.of(c).copyWith(
          size: constraints.biggest,
        );
        return MediaQuery(
          data: newData,
          child: _CropEditor(
            image: image,
            onCropped: (croppedImage) {
              Navigator.of(context).pop(croppedImage);
            },
            aspectRatio: null,
            initialSize: 0.5,
            initialArea: null,
            withCircleUi: false,
            controller: controller,
            onMoved: null,
            baseColor: Colors.white,
          ),
        );
      },
    );
  }
}

class _CropEditor extends StatefulWidget {
  final Uint8List image;
  final ValueChanged<Uint8List> onCropped;
  final double? aspectRatio;
  final double? initialSize;
  final Rect? initialArea;
  final bool withCircleUi;
  final CropController? controller;
  final ValueChanged<Rect>? onMoved;
  final Color baseColor;
  final CornerDotBuilder? cornerDotBuilder;

  const _CropEditor({
    Key? key,
    required this.image,
    required this.onCropped,
    this.aspectRatio,
    this.initialSize,
    this.initialArea,
    this.withCircleUi = false,
    this.controller,
    this.onMoved,
    required this.baseColor,
    this.cornerDotBuilder,
  }) : super(key: key);

  @override
  _CropEditorState createState() => _CropEditorState();
}

class _CropEditorState extends State<_CropEditor> {
  late CropController _cropController;
  late Rect _rect;
  image.Image? _targetImage;
  late Rect _imageRect;
  late double statusBarHeight;
  bool _ignoring = false;
  final _repaintBoundaryKey = GlobalKey();

  double? _aspectRatio;
  String? _aspectValue = 'FREE';
  // bool _withCircleUi = false;
  bool _isFitVertically = false;

  _Calculator get calculator => _isFitVertically
      ? _VerticalCalculator(MediaQuery.of(context).padding.top)
      : _HorizontalCalculator(MediaQuery.of(context).padding.top);

  set rect(Rect newRect) {
    setState(() {
      _rect = newRect;
    });
    widget.onMoved?.call(_rect);
  }

  @override
  void initState() {
    _cropController = widget.controller ?? CropController();
    _cropController.delegate = CropControllerDelegate()
      ..onCrop = _crop
      ..onChangeAspectRatio = (aspectRatio) {
        _resizeWith(aspectRatio, null);
      }
      ..onImageChanged = _resetImage
      ..onChangeRect = (newRect) {
        rect = calculator.correct(newRect, _imageRect);
      }
      ..onChangeArea = (newArea) {
        _resizeWith(_aspectRatio, newArea);
      };

    super.initState();
  }

  @override
  void didChangeDependencies() {
    print("AR::: didChangeDependencies");
    _targetImage = _fromByteData(widget.image);
    _resetCroppingArea();
    super.didChangeDependencies();
  }

  // decode orientation awared Image.
  image.Image? _fromByteData(Uint8List data) {
    final tempImage = image.decodeImage(data);
    assert(tempImage != null);

    // check orientation
    switch (tempImage?.exif.data[0x0112] ?? -1) {
      case 3:
        return image.copyRotate(tempImage!, 180);
      case 6:
        return image.copyRotate(tempImage!, 90);
      case 8:
        return image.copyRotate(tempImage!, -90);
    }
    return tempImage;
  }

  // reset image to be cropped
  void _resetImage(Uint8List targetImage) {
    setState(() {
      _targetImage = _fromByteData(targetImage);
    });
    _resetCroppingArea();
  }

  /// reset [Rect] of cropping area with current state
  void _resetCroppingArea() {
    final screenSize = MediaQuery.of(context).size;

    final imageRatio = _targetImage!.width / _targetImage!.height;
    _isFitVertically = imageRatio < screenSize.aspectRatio;

    _imageRect = calculator.imageRect(screenSize, imageRatio);

    _resizeWith(widget.aspectRatio, widget.initialArea);
  }

  /// resize cropping area with given aspect ratio.
  void _resizeWith(double? aspectRatio, Rect? initialArea) {
    _aspectRatio =  aspectRatio;

    if (initialArea == null) {
      rect = calculator.initialCropRect(
        MediaQuery.of(context).size,
        _imageRect,
        _aspectRatio ?? 1,
        widget.initialSize ?? 1,
      );
    } else {
      final screenSizeRatio = calculator.screenSizeRatio(
        _targetImage!,
        MediaQuery.of(context).size,
      );
      rect = Rect.fromLTWH(
        _imageRect.left + initialArea.left / screenSizeRatio,
        _imageRect.top + initialArea.top / screenSizeRatio,
        initialArea.width / screenSizeRatio,
        initialArea.height / screenSizeRatio,
      );
    }
  }

  /// crop given image with given area.
  Future<void> _crop(bool withCircleShape) async {
    assert(_targetImage != null);

    RenderRepaintBoundary? boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
    ui.Image renderImage = await boundary.toImage(pixelRatio: 2);
    ByteData? byteData = await renderImage.toByteData(format: ui.ImageByteFormat.png);
    var pngBytes = byteData?.buffer.asUint8List();
    List<int>? bytes = pngBytes?.toList();
    image.Image? finalImage = image.decodeImage(bytes as List<int>);

    final screenSizeRatio = calculator.screenSizeRatio(
      finalImage!,
      MediaQuery.of(context).size,
    );

    // use compute() not to block UI update
    final cropResult = await compute(
      withCircleShape ? _doCropCircle : _doCrop,
      [
        finalImage,
        Rect.fromLTWH(
          (_rect.left - _imageRect.left) * screenSizeRatio,
          (_rect.top - _imageRect.top) * screenSizeRatio,
          _rect.width * screenSizeRatio,
          _rect.height * screenSizeRatio,
        ),
      ],
    );
    widget.onCropped(cropResult);
  }

  Widget _buildAspectRatioButton(String title, double value) {
    return Expanded(
      child: FlatButton(
        child: Text(
          title,
          style: TextStyle(
            color: _aspectValue == title ? Colors.deepPurple : Colors.black,
          ),
        ),
        onPressed: () {
          if (_aspectValue != title) {
            setState(() {
              _aspectValue = title;
              _cropController.aspectRatio = value;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: IgnorePointer(
        ignoring: _ignoring,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Crop'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.check),
                tooltip: 'Crop',
                onPressed: () async {
                  _cropController.crop();
                  setState(() {
                    _ignoring = true;
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: RepaintBoundary(
                        key: _repaintBoundaryKey,
                        child: InteractiveViewer(
                          onInteractionEnd: (ScaleEndDetails endDetails) {
                            print(endDetails);
                          },
                          // child: Container(
                          //   color: widget.baseColor,
                          //   width: MediaQuery.of(context).size.width,
                          // height: MediaQuery.of(context).size.height -
                          //     AppBar().preferredSize.height,
                          child: Image.memory(
                            widget.image,
                            fit: _isFitVertically
                                ? BoxFit.fitHeight
                                : BoxFit.fitWidth,
                          ),
                          // ),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: ClipPath(
                        clipper: _CropAreaClipper(_rect),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.black.withAlpha(100),
                        ),
                      ),
                    ),
                    Positioned(
                      left: _rect.left,
                      top: _rect.top,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          rect = calculator.moveRect(
                            _rect,
                            details.delta.dx,
                            details.delta.dy,
                            _imageRect,
                          );
                        },
                        child: Container(
                          width: _rect.width,
                          height: _rect.height,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                    Positioned(
                      left: _rect.left - (dotTotalSize / 2),
                      top: _rect.top - (dotTotalSize / 2),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          rect = calculator.moveTopLeft(
                            _rect,
                            details.delta.dx,
                            details.delta.dy,
                            _imageRect,
                            _aspectRatio,
                          );
                        },
                        child: widget.cornerDotBuilder?.call(dotTotalSize, 0) ??
                            const DotControl(),
                      ),
                    ),
                    Positioned(
                      left: _rect.right - (dotTotalSize / 2),
                      top: _rect.top - (dotTotalSize / 2),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          rect = calculator.moveTopRight(
                            _rect,
                            details.delta.dx,
                            details.delta.dy,
                            _imageRect,
                            _aspectRatio,
                          );
                        },
                        child: widget.cornerDotBuilder?.call(dotTotalSize, 1) ??
                            const DotControl(),
                      ),
                    ),
                    Positioned(
                      left: _rect.left - (dotTotalSize / 2),
                      top: _rect.bottom - (dotTotalSize / 2),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          rect = calculator.moveBottomLeft(
                            _rect,
                            details.delta.dx,
                            details.delta.dy,
                            _imageRect,
                            _aspectRatio,
                          );
                        },
                        child: widget.cornerDotBuilder?.call(dotTotalSize, 2) ??
                            const DotControl(),
                      ),
                    ),
                    Positioned(
                      left: _rect.right - (dotTotalSize / 2),
                      top: _rect.bottom - (dotTotalSize / 2),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          rect = calculator.moveBottomRight(
                            _rect,
                            details.delta.dx,
                            details.delta.dy,
                            _imageRect,
                            _aspectRatio,
                          );
                        },
                        child: widget.cornerDotBuilder?.call(dotTotalSize, 3) ??
                            const DotControl(),
                      ),
                    ),
                    //top
                    Positioned(
                      left:
                          (_rect.left + (_rect.width / 2)) - (dotTotalSize / 2),
                      top: _rect.top - (dotTotalSize / 2),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          rect = calculator.moveTop(
                            _rect,
                            details.delta.dx,
                            details.delta.dy,
                            _imageRect,
                            _aspectRatio,
                          );
                        },
                        child: widget.cornerDotBuilder?.call(dotTotalSize, 3) ??
                            const DotControl(),
                      ),
                    ),
                    //bottom
                    Positioned(
                      left:
                          (_rect.left + (_rect.width / 2)) - (dotTotalSize / 2),
                      top: _rect.bottom - (dotTotalSize / 2),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          rect = calculator.moveBottom(
                            _rect,
                            details.delta.dx,
                            details.delta.dy,
                            _imageRect,
                            _aspectRatio,
                          );
                        },
                        child: widget.cornerDotBuilder?.call(dotTotalSize, 3) ??
                            const DotControl(),
                      ),
                    ),
                    //left
                    Positioned(
                      left: (_rect.left) - (dotTotalSize / 2),
                      top:
                          (_rect.top + (_rect.height / 2)) - (dotTotalSize / 2),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          rect = calculator.moveLeft(
                            _rect,
                            details.delta.dx,
                            details.delta.dy,
                            _imageRect,
                            _aspectRatio,
                          );
                        },
                        child: widget.cornerDotBuilder?.call(dotTotalSize, 3) ??
                            const DotControl(),
                      ),
                    ),
                    //right
                    Positioned(
                      left: (_rect.right) - (dotTotalSize / 2),
                      top:
                          (_rect.top + (_rect.height / 2)) - (dotTotalSize / 2),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          rect = calculator.moveRight(
                            _rect,
                            details.delta.dx,
                            details.delta.dy,
                            _imageRect,
                            _aspectRatio,
                          );
                        },
                        child: widget.cornerDotBuilder?.call(dotTotalSize, 3) ??
                            const DotControl(),
                      ),
                    ),
                    if (_ignoring) Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAspectRatioButton('1:1', 1.0),
                  _buildAspectRatioButton('3:4', 3.0 / 4.0),
                  Expanded(
                    child: FittedBox(
                      child: FlatButton(
                        child: Text(
                          'FREE',
                          style: TextStyle(
                            color: _aspectValue == 'FREE'
                                ? Colors.deepPurple
                                : Colors.black,
                          ),
                        ),
                        onPressed: () {
                          if (_aspectValue != 'FREE') {
                            setState(() {
                              _aspectValue = 'FREE';
                              _cropController.aspectRatio = null;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  _buildAspectRatioButton('4:3', 4.0 / 3.0),
                  _buildAspectRatioButton('16:9', 16.0 / 9.0),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropAreaClipper extends CustomClipper<Path> {
  final Rect rect;

  _CropAreaClipper(this.rect);

  @override
  Path getClip(Size size) {
    return Path()
      ..addPath(
        Path()
          ..moveTo(rect.left, rect.top)
          ..lineTo(rect.right, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close(),
        Offset.zero,
      )
      ..addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

/// Defalt dot widget placed on corners to control cropping area.
/// This Widget automaticall fits the appropriate size.
class DotControl extends StatelessWidget {
  const DotControl({
    Key? key,
    this.color = Colors.white,
    this.padding = 8,
  }) : super(key: key);

  /// [Color] of this widget. [Colors.white] by default.
  final Color color;

  /// The size of transparent padding which exists to make dot easier to touch.
  /// Though total size of this widget cannot be changed,
  /// but visible size can be changed by setting this value.
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      width: dotTotalSize,
      height: dotTotalSize,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(dotTotalSize),
          child: Container(
            width: dotTotalSize - (padding * 2),
            height: dotTotalSize - (padding * 2),
            color: color,
          ),
        ),
      ),
    );
  }
}

/// process cropping image.
/// this method is supposed to be called only via compute()
Uint8List _doCrop(List<dynamic> cropData) {
  final originalImage = cropData[0] as image.Image;
  final rect = cropData[1] as Rect;
  return Uint8List.fromList(
    image.encodePng(
      image.copyCrop(
        originalImage,
        rect.left.toInt(),
        rect.top.toInt(),
        rect.width.toInt(),
        rect.height.toInt(),
      ),
    ),
  );
}

/// process cropping image with circle shape.
/// this method is supposed to be called only via compute()
Uint8List _doCropCircle(List<dynamic> cropData) {
  final originalImage = cropData[0] as image.Image;
  final rect = cropData[1] as Rect;
  return Uint8List.fromList(
    image.encodePng(
      image.copyCropCircle(
        originalImage,
        center:
            image.Point(rect.left + rect.width / 2, rect.top + rect.height / 2),
        radius: min(rect.width, rect.height) ~/ 2,
      ),
    ),
  );
}
