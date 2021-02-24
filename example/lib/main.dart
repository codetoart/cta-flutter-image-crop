import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_clip/image_clip.dart' as ic;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Clip',
      theme: ThemeData.light().copyWith(primaryColor: Colors.deepPurple),
      home: MyHomePage(title: 'Image Clip'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({this.title});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

enum AppState {
  free,
  picked,
  cropped,
}

class _MyHomePageState extends State<MyHomePage> {
  AppState state;
  File imageFile;
  double aspectRatio;
  ui.Image croppedImage;

  @override
  void initState() {
    super.initState();
    state = AppState.free;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: croppedImage != null
          ? Center(
              child: RawImage(image: croppedImage),
            )
          : Center(
              child: imageFile != null ? Image.file(imageFile) : Container(),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          if (state == AppState.free)
            _pickImage();
          else if (state == AppState.picked)
            _cropImage();
          else if (state == AppState.cropped) _clearImage();
        },
        child: _buildButtonIcon(),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _buildButtonIcon() {
    if (state == AppState.free)
      return Icon(Icons.add);
    else if (state == AppState.picked)
      return Icon(Icons.crop);
    else if (state == AppState.cropped)
      return Icon(Icons.clear);
    else
      return Container();
  }

  Future<void> getImageFromPath(File imageFile) async {
    Completer<ImageInfo> completer = Completer();
    var img = FileImage(imageFile);
    img
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info);
    }));
    ImageInfo imageInfo = await completer.future;
    final imageP = imageInfo.image;
    aspectRatio = imageP.width / imageP.height;
  }

  Future<Null> _pickImage() async {
    final picker = ImagePicker();
    final pickedImageFile = await picker.getImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );

    if (pickedImageFile != null) {
      await getImageFromPath(File(pickedImageFile.path));
      setState(() {
        imageFile = File(pickedImageFile.path);
        state = AppState.picked;
      });
    }
  }

  Future<Null> _cropImage() async {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return ic.Crop(
          imageFile: imageFile,
          imageAspectRatio: aspectRatio,
        );
      },
    )).then((image) {
      setState(() {
        if (image != null) {
          croppedImage = image;
          state = AppState.cropped;
        }
      });
    });
    // setState(() {
    //   imageFile = null;
    //   state = AppState.free;
    // });
  }

  void _clearImage() {
    setState(() {
      croppedImage = null;
      imageFile = null;
      state = AppState.free;
    });
  }
}
