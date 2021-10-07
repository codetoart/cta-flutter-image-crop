import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart' as ic;

import 'package:share/share.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Clip',
      theme: ThemeData.light().copyWith(primaryColor: Colors.blue),
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
  Uint8List croppedImage;

  final _cropController = ic.CropController();

  @override
  void initState() {
    super.initState();
    state = AppState.free;
    _pickImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: croppedImage != null
          ? Center(
              child: Image.memory(croppedImage),
            )
          : Center(
              child: imageFile != null ? Image.file(imageFile) : Container(),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () async {
          if (state == AppState.free)
            _pickImage();
          else if (state == AppState.picked)
            _cropImage();
          else if (state == AppState.cropped) {
            // _clearImage();
            Directory dir =
        await getApplicationDocumentsDirectory();
        File image = await File('${dir.path}/${p.basename(imageFile.path)}').writeAsBytes(croppedImage);
            await Share.shareFiles([image.path]);
          }
        },
        child: _buildButtonIcon(),
      ),
    );
  }

  Widget _buildButtonIcon() {
    if (state == AppState.free)
      return Icon(Icons.add);
    else if (state == AppState.picked)
      return Icon(Icons.crop);
    else if (state == AppState.cropped)
      return Icon(Icons.share);
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
    final pickedImageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
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
    var file = await imageFile.readAsBytes();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return ic.Crop(
          controller: _cropController,
          image: file,
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
  }

  void _clearImage() {
    setState(() {
      croppedImage = null;
      imageFile = null;
      state = AppState.free;
    });
  }
}
