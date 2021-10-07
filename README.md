# image_cropper

**A flutter package to scale and crop images. Optinally set aspect ratio of cropping area**

<img alt="Demo" src="https://raw.githubusercontent.com/codetoart/cta-flutter-image-crop/develop/readme-assets/image_crop_demo.gif" height="500">

## Documentation

### Installation
Add `image_cropper` to your `pubspec.yaml`:

```
dependencies:
  flutter:
    sdk: flutter

  # added below
  image_cropper: <latest version>
```
### Adding to app
When you have the image file navigate to `Crop` widget provided by the package

```
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
          
```

### Author
[**CodeToArt Technology**](https://github.com/codetoart)

- Follow us on **Twitter**: [**@codetoart**](https://twitter.com/codetoart)
- Contact us on **Website**: [**codetoart**](http://www.codetoart.com)
