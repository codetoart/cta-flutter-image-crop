import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import './customsliderthumbcircle.dart';
import './cropper.dart';
import 'dart:ui' as ui;

class Crop extends StatefulWidget {
  final File imageFile;

  Crop({@required this.imageFile});

  @override
  _CropState createState() => _CropState();
}

class _CropState extends State<Crop> with TickerProviderStateMixin {
  final GlobalKey _containerKey = GlobalKey();
  final controller = CropController(aspectRatio: 1.0);
  double _rotation = 0;
  double _value;
  double _aspectValueOriginal;
  String _aspectValue = 'ORIGINAL';
  ui.Image imageP;
  AppBar appbar;

  Future<void> getImageFromPath(String path) async {
    Completer<ImageInfo> completer = Completer();
    var img = FileImage(widget.imageFile);
    img
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info);
    }));
    ImageInfo imageInfo = await completer.future;
    imageP = imageInfo.image;
    setState(() {
      _aspectValueOriginal = imageP.width / imageP.height;
      controller.aspectRatio = _aspectValueOriginal;
    });
  }

  @override
  void initState() {
    super.initState();
    getImageFromPath(widget.imageFile.path);
  }

  void _cropImage(ui.Image croppedImage) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Crop Result'),
            centerTitle: true,
          ),
          body: Center(
            child: RawImage(
              image: croppedImage,
            ),
          ),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  double getContainerSize() {
    final RenderBox renderBox = _containerKey.currentContext.findRenderObject();
    final size = renderBox.size;
    return size.width / size.height;
  }

  Widget getAppBar(BuildContext context) {
    appbar = AppBar(
      title: Text('Crop'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.crop),
          tooltip: 'Crop',
          onPressed: () async {
            final pixelRatio = MediaQuery.of(context).devicePixelRatio;
            final cropped = await controller.crop(pixelRatio: pixelRatio);
            _cropImage(cropped);
          },
        ),
      ],
    );
    return appbar;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: getAppBar(context),
        body: Column(
          children: [
            Expanded(
              child: Container(
                key: _containerKey,
                color: Colors.black,
                padding: EdgeInsets.all(8),
                child: Cropper(
                  onChangedInfo: (stateinfo) {
                    print(
                        "Scale : ${stateinfo.scale}, Rotation: ${stateinfo.rotation}, translation: ${stateinfo.translation}");
                  },
                  child: Align(
                    alignment: Alignment.center,
                    child: AspectRatio(
                      aspectRatio: _aspectValue == 'ORIGINAL'
                          ? _aspectValueOriginal
                          : getContainerSize(),
                      child: Image.file(
                        widget.imageFile,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  cropController: controller,
                  helper: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.deepPurple, width: 2),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: FlatButton(
                    child: Text(
                      '1:1',
                      style: TextStyle(
                          color: _aspectValue == '1:1'
                              ? Colors.deepPurple
                              : Colors.black),
                    ),
                    onPressed: () {
                      setState(() {
                        _aspectValue = '1:1';
                        _value = 1.0;
                        controller.aspectRatio = _value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: FlatButton(
                    child: Text(
                      '3:2',
                      style: TextStyle(
                          color: _aspectValue == '3:2'
                              ? Colors.deepPurple
                              : Colors.black),
                    ),
                    onPressed: () {
                      setState(() {
                        _aspectValue = '3:2';
                        _value = 3.0 / 2.0;
                        controller.aspectRatio = _value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: FittedBox(
                    child: FlatButton(
                      child: Text(
                        'ORIGINAL',
                        style: TextStyle(
                            color: _aspectValue == 'ORIGINAL'
                                ? Colors.deepPurple
                                : Colors.black),
                      ),
                      onPressed: () {
                        setState(() {
                          _aspectValue = 'ORIGINAL';
                          // _value = 1.0 / 1.0;
                          print('aspectoriginal');
                          print(_aspectValueOriginal);
                          controller.aspectRatio = _aspectValueOriginal;
                        });
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: FlatButton(
                    child: Text(
                      '4:3',
                      style: TextStyle(
                          color: _aspectValue == '4:3'
                              ? Colors.deepPurple
                              : Colors.black),
                    ),
                    onPressed: () {
                      setState(() {
                        _aspectValue = '4:3';
                        _value = 4.0 / 3.0;
                        controller.aspectRatio = _value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: FlatButton(
                    child: Text(
                      '16:9',
                      style: TextStyle(
                          color: _aspectValue == '16:9'
                              ? Colors.deepPurple
                              : Colors.black),
                    ),
                    onPressed: () {
                      setState(() {
                        _aspectValue = '16:9';
                        _value = 16.0 / 9.0;
                        controller.aspectRatio = _value;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.undo),
                  tooltip: 'Undo',
                  onPressed: () {},
                ),
                Expanded(
                  child: Container(
                    width: 45.0 * 5.5,
                    height: 45.0,
                    padding: EdgeInsets.all(6.0),
                    decoration: new BoxDecoration(
                      borderRadius: new BorderRadius.all(
                        Radius.circular((45.0 * .3)),
                      ),
                      gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00c6ff),
                            const Color(0xFF0072ff),
                          ],
                          begin: const FractionalOffset(0.0, 0.0),
                          end: const FractionalOffset(1.0, 1.00),
                          stops: [0.0, 1.0],
                          tileMode: TileMode.clamp),
                    ),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white70,
                        trackShape: RoundedRectSliderTrackShape(),
                        trackHeight: 2.0,
                        thumbShape: CustomSliderThumbRect(
                          thumbRadius: 20.0,
                          thumbHeight: 45.0,
                          max: 180,
                          min: -180,
                        ),
                      ),
                      child: Slider.adaptive(
                        value: _rotation,
                        min: -180,
                        max: 180,
                        label: '$_rotation',
                        onChanged: (value) {
                          setState(() {
                            _rotation = value.roundToDouble();
                            controller.rotation = _rotation;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
              ],
            ),
            SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
