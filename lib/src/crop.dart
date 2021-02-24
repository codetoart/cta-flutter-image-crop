import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import './customsliderthumbcircle.dart';
import './cropper.dart';

class Crop extends StatefulWidget {
  final File imageFile;
  final double imageAspectRatio;

  Crop({@required this.imageFile, @required this.imageAspectRatio});

  @override
  _CropState createState() => _CropState();
}

class _CropState extends State<Crop> with TickerProviderStateMixin {
  final GlobalKey _containerKey = GlobalKey();
  CropController controller;
  double _rotation = 0;
  double _value;
  double _aspectValueOriginal;
  String _aspectValue = 'ORIGINAL';
  AppBar _appbar;
  AnimationController controller1;
  Animation heartbeatAnimation;
  bool _showInitialOriginalAR = true;

  @override
  void initState() {
    super.initState();
    controller = CropController(aspectRatio: widget.imageAspectRatio);
    _aspectValueOriginal = widget.imageAspectRatio;
  }

  void _cropImage(ui.Image croppedImage) {
    Navigator.of(context).pop(croppedImage);
  }

  double _getContainerSize() {
    final RenderBox renderBox = _containerKey.currentContext.findRenderObject();
    final size = renderBox.size;
    return size.width / size.height;
  }

  Widget _getAppBar(BuildContext context) {
    _appbar = AppBar(
      title: Text('Crop'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.check),
          tooltip: 'Crop',
          onPressed: () async {
            final pixelRatio = MediaQuery.of(context).devicePixelRatio;
            final croppedImage = await controller.crop(pixelRatio: pixelRatio);
            _cropImage(croppedImage);
          },
        ),
      ],
    );
    return _appbar;
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
              _value = value;
              controller.aspectRatio = _value;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: _getAppBar(context),
        body: Column(
          children: [
            Expanded(
              child: Container(
                key: _containerKey,
                color: Colors.black,
                padding: EdgeInsets.all(8),
                child: Cropper(
                  child: Align(
                    alignment: Alignment.center,
                    child: AspectRatio(
                      aspectRatio: _aspectValue == 'ORIGINAL'
                          ? _aspectValueOriginal
                          : _getContainerSize(),
                      child:
                          _aspectValue == 'ORIGINAL' && _showInitialOriginalAR
                              ? Image.file(
                                  widget.imageFile,
                                  fit: BoxFit.cover,
                                )
                              : OverflowBox(
                                  minHeight: 0.0,
                                  minWidth: 0.0,
                                  maxWidth: double.infinity,
                                  maxHeight: double.infinity,
                                  child: Image.file(
                                    widget.imageFile,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                    ),
                  ),
                  cropController: controller,
                  rectView: Container(
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
                _buildAspectRatioButton('1:1', 1.0),
                _buildAspectRatioButton('3:4', 3.0 / 4.0),
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
                        if (_aspectValue != 'ORIGINAL') {
                          setState(() {
                            _showInitialOriginalAR = false;
                            _aspectValue = 'ORIGINAL';
                            controller.aspectRatio = _aspectValueOriginal;
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
            SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.undo),
                  tooltip: 'Undo',
                  onPressed: () {
                    controller.rotation = 0;
                    controller.scale = 1;
                    controller.offset = Offset.zero;
                    controller.aspectRatio = _aspectValueOriginal;
                    setState(() {
                      _showInitialOriginalAR = true;
                      _aspectValue = 'ORIGINAL';
                      _rotation = 0;
                    });
                  },
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
                        onChanged: (value) {},
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
