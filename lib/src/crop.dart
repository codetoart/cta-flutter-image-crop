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
  final controller = CropController(aspectRatio: 1000 / 667.0);
  double _rotation = 0;
  double _value = 1000 / 667.0;
  String _aspectValue = 'ORIGINAL';
  ui.Image imageP;

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
  }

  @override
  void initState() {
    super.initState();
    getImageFromPath(widget.imageFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(8),
              child: Cropper(
                child: Image.file(
                  widget.imageFile,
                  fit: BoxFit.cover,
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
                      _value = 1;
                      controller.aspectRatio = _value;
                    });
                  },
                ),
              ),
              Expanded(
                child: FlatButton(
                  child: Text(
                    '3:4',
                    style: TextStyle(
                        color: _aspectValue == '3:4'
                            ? Colors.deepPurple
                            : Colors.black),
                  ),
                  onPressed: () {
                    setState(() {
                      _aspectValue = '3:4';
                      _value = 3.0 / 4.0;
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
                        _value = 1000 / 667.0;
                        controller.aspectRatio = _value;
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
    );
  }
}
