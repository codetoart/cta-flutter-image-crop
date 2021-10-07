part of image_cropper;

/// Calculation logics for various [Rect] data.
abstract class _Calculator {
  const _Calculator(this.statusBarHeight);
  final statusBarHeight;

  get appBarHeight {
    return AppBar().preferredSize.height + statusBarHeight + 50;
  }

  /// calculates [Rect] of image to fit the screenSize.
  Rect imageRect(Size screenSize, double imageRatio);

  /// calculates [Rect] of initial cropping area.
  Rect initialCropRect(
      Size screenSize, Rect imageRect, double aspectRatio, double sizeRatio);

  /// calculates ratio of [targetImage] and [screenSize]
  double screenSizeRatio(image.Image targetImage, Size screenSize);

  /// calculates [Rect] of the result of user moving the cropping area.
  Rect moveRect(Rect original, double deltaX, double deltaY, Rect imageRect) {
    if (original.left + deltaX < imageRect.left) {
      deltaX = (original.left - imageRect.left) * -1;
    }
    if (original.right + deltaX > imageRect.right) {
      deltaX = imageRect.right - original.right;
    }
    if (original.top + deltaY < imageRect.top) {
      deltaY = (original.top - imageRect.top) * -1;
    }
    if (original.bottom + deltaY > imageRect.bottom) {
      deltaY = imageRect.bottom - original.bottom;
    }
    return Rect.fromLTWH(
      original.left + deltaX,
      original.top + deltaY,
      original.width,
      original.height,
    );
  }

  /// calculates [Rect] of the result of user moving the top-left dot.
  Rect moveTopLeft(Rect original, double deltaX, double deltaY, Rect imageRect,
      double? aspectRatio) {
    final newLeft =
        max(imageRect.left, min(original.left + deltaX, original.right - 40));
    final newTop =
        min(max(original.top + deltaY, imageRect.top), original.bottom - 40);
    if (aspectRatio == null) {
      return Rect.fromLTRB(
        newLeft,
        newTop,
        original.right,
        original.bottom,
      );
    } else {
      if (deltaX.abs() > deltaY.abs()) {
        var newWidth = original.right - newLeft;
        var newHeight = newWidth / aspectRatio;
        if (original.bottom - newHeight < imageRect.top) {
          newHeight = original.bottom - imageRect.top;
          newWidth = newHeight * aspectRatio;
        }

        return Rect.fromLTRB(
          original.right - newWidth,
          original.bottom - newHeight,
          original.right,
          original.bottom,
        );
      } else {
        var newHeight = original.bottom - newTop;
        var newWidth = newHeight * aspectRatio;
        if (original.right - newWidth < imageRect.left) {
          newWidth = original.right - imageRect.left;
          newHeight = newWidth / aspectRatio;
        }
        return Rect.fromLTRB(
          original.right - newWidth,
          original.bottom - newHeight,
          original.right,
          original.bottom,
        );
      }
    }
  }

  /// calculates [Rect] of the result of user moving the top-right dot.
  Rect moveTopRight(Rect original, double deltaX, double deltaY, Rect imageRect,
      double? aspectRatio) {
    final newTop =
        min(max(original.top + deltaY, imageRect.top), original.bottom - 40);
    final newRight =
        max(min(original.right + deltaX, imageRect.right), original.left + 40);
    if (aspectRatio == null) {
      return Rect.fromLTRB(
        original.left,
        newTop,
        newRight,
        original.bottom,
      );
    } else {
      if (deltaX.abs() > deltaY.abs()) {
        var newWidth = newRight - original.left;
        var newHeight = newWidth / aspectRatio;
        if (original.bottom - newHeight < imageRect.top) {
          newHeight = original.bottom - imageRect.top;
          newWidth = newHeight * aspectRatio;
        }

        return Rect.fromLTWH(
          original.left,
          original.bottom - newHeight,
          newWidth,
          newHeight,
        );
      } else {
        var newHeight = original.bottom - newTop;
        var newWidth = newHeight * aspectRatio;
        if (original.left + newWidth > imageRect.right) {
          newWidth = imageRect.right - original.left;
          newHeight = newWidth / aspectRatio;
        }
        return Rect.fromLTRB(
          original.left,
          original.bottom - newHeight,
          original.left + newWidth,
          original.bottom,
        );
      }
    }
  }

  /// calculates [Rect] of the result of user moving the bottom-left dot.
  Rect moveBottomLeft(Rect original, double deltaX, double deltaY,
      Rect imageRect, double? aspectRatio) {
    final newLeft =
        max(imageRect.left, min(original.left + deltaX, original.right - 40));
    final newBottom =
        max(min(original.bottom + deltaY, imageRect.bottom), original.top + 40);

    if (aspectRatio == null) {
      return Rect.fromLTRB(
        newLeft,
        original.top,
        original.right,
        newBottom,
      );
    } else {
      if (deltaX.abs() > deltaY.abs()) {
        var newWidth = original.right - newLeft;
        var newHeight = newWidth / aspectRatio;
        if (original.top + newHeight > imageRect.bottom) {
          newHeight = imageRect.bottom - original.top;
          newWidth = newHeight * aspectRatio;
        }

        return Rect.fromLTRB(
          original.right - newWidth,
          original.top,
          original.right,
          original.top + newHeight,
        );
      } else {
        var newHeight = newBottom - original.top;
        var newWidth = newHeight * aspectRatio;
        if (original.right - newWidth < imageRect.left) {
          newWidth = original.right - imageRect.left;
          newHeight = newWidth / aspectRatio;
        }
        return Rect.fromLTRB(
          original.right - newWidth,
          original.top,
          original.right,
          original.top + newHeight,
        );
      }
    }
  }

  /// calculates [Rect] of the result of user moving the bottom-right dot.
  Rect moveBottomRight(Rect original, double deltaX, double deltaY,
      Rect imageRect, double? aspectRatio) {
    final newRight =
        min(imageRect.right, max(original.right + deltaX, original.left + 40));
    final newBottom =
        max(min(original.bottom + deltaY, imageRect.bottom), original.top + 40);
    if (aspectRatio == null) {
      return Rect.fromLTRB(
        original.left,
        original.top,
        newRight,
        newBottom,
      );
    } else {
      if (deltaX.abs() > deltaY.abs()) {
        var newWidth = newRight - original.left;
        var newHeight = newWidth / aspectRatio;
        if (original.top + newHeight > imageRect.bottom) {
          newHeight = imageRect.bottom - original.top;
          newWidth = newHeight * aspectRatio;
        }

        return Rect.fromLTWH(
          original.left,
          original.top,
          newWidth,
          newHeight,
        );
      } else {
        var newHeight = newBottom - original.top;
        var newWidth = newHeight * aspectRatio;
        if (original.left + newWidth > imageRect.right) {
          newWidth = imageRect.right - original.left;
          newHeight = newWidth / aspectRatio;
        }
        return Rect.fromLTWH(
          original.left,
          original.top,
          newWidth,
          newHeight,
        );
      }
    }
  }

  /// calculates [Rect] of the result of user moving the top dot.
  Rect moveTop(Rect original, double deltaX, double deltaY, Rect imageRect,
      double? aspectRatio) {
    final newLeft =
        max(imageRect.left, min(original.left + deltaX, original.right - 40));
    final newTop =
        min(max(original.top + deltaY, imageRect.top), original.bottom - 40);
    if (aspectRatio == null) {
      return Rect.fromLTRB(
        original.left,
        newTop,
        original.right,
        original.bottom,
      );
    } else {
      if (deltaX.abs() > deltaY.abs()) {
        var newWidth = original.right - original.left;
        var newHeight = newWidth / aspectRatio;
        if (original.bottom - newHeight < imageRect.top) {
          newHeight = original.bottom - imageRect.top;
          newWidth = newHeight * aspectRatio;
        }

        return Rect.fromLTRB(
          original.right - newWidth,
          original.bottom - newHeight,
          original.right,
          original.bottom,
        );
      } else {
        var newHeight = original.bottom - newTop;
        var newWidth = newHeight * aspectRatio;
        if (original.right - newWidth < imageRect.left) {
          newWidth = original.right - imageRect.left;
          newHeight = newWidth / aspectRatio;
        }
        return Rect.fromLTRB(
          original.right - newWidth,
          original.bottom - newHeight,
          original.right,
          original.bottom,
        );
      }
    }
  }

  /// calculates [Rect] of the result of user moving the bottom dot.
  Rect moveBottom(Rect original, double deltaX, double deltaY, Rect imageRect,
      double? aspectRatio) {
    final newBottom =
        max(min(original.bottom + deltaY, imageRect.bottom), original.top + 40);
    if (aspectRatio == null) {
      return Rect.fromLTRB(
        original.left,
        original.top,
        original.right,
        newBottom,
      );
    } else {
      if (deltaX.abs() > deltaY.abs()) {
        var newWidth = original.right - original.left;
        var newHeight = newWidth / aspectRatio;
        if (original.top + newHeight > imageRect.bottom) {
          newHeight = imageRect.bottom - original.top;
          newWidth = newHeight * aspectRatio;
        }

        return Rect.fromLTWH(
          original.left,
          original.top,
          newWidth,
          newHeight,
        );
      } else {
        var newHeight = newBottom - original.top;
        var newWidth = newHeight * aspectRatio;
        if (original.left + newWidth > imageRect.right) {
          newWidth = imageRect.right - original.left;
          newHeight = newWidth / aspectRatio;
        }
        return Rect.fromLTWH(
          original.left,
          original.top,
          newWidth,
          newHeight,
        );
      }
    }
  }

  /// calculates [Rect] of the result of user moving the right dot.
  Rect moveRight(Rect original, double deltaX, double deltaY, Rect imageRect,
      double? aspectRatio) {
    final newRight =
        min(imageRect.right, max(original.right + deltaX, original.left + 40));
    if (aspectRatio == null) {
      return Rect.fromLTRB(
        original.left,
        original.top,
        newRight,
        original.bottom,
      );
    } else {
      if (deltaX.abs() > deltaY.abs()) {
        var newWidth = newRight - original.left;
        var newHeight = newWidth / aspectRatio;
        if (original.top + newHeight > imageRect.bottom) {
          newHeight = imageRect.bottom - original.top;
          newWidth = newHeight * aspectRatio;
        }

        return Rect.fromLTWH(
          original.left,
          original.top,
          newWidth,
          newHeight,
        );
      } else {
        var newHeight = original.bottom - original.top;
        var newWidth = newHeight * aspectRatio;
        if (original.left + newWidth > imageRect.right) {
          newWidth = imageRect.right - original.left;
          newHeight = newWidth / aspectRatio;
        }
        return Rect.fromLTWH(
          original.left,
          original.top,
          newWidth,
          newHeight,
        );
      }
    }
  }

  /// calculates [Rect] of the result of user moving the left dot.
  Rect moveLeft(Rect original, double deltaX, double deltaY, Rect imageRect,
      double? aspectRatio) {
    final newLeft =
        max(imageRect.left, min(original.left + deltaX, original.right - 40));

    if (aspectRatio == null) {
      return Rect.fromLTRB(
        newLeft,
        original.top,
        original.right,
        original.bottom,
      );
    } else {
      if (deltaX.abs() > deltaY.abs()) {
        var newWidth = original.right - newLeft;
        var newHeight = newWidth / aspectRatio;
        if (original.top + newHeight > imageRect.bottom) {
          newHeight = imageRect.bottom - original.top;
          newWidth = newHeight * aspectRatio;
        }

        return Rect.fromLTRB(
          original.right - newWidth,
          original.top,
          original.right,
          original.top + newHeight,
        );
      } else {
        var newHeight = original.bottom - original.top;
        var newWidth = newHeight * aspectRatio;
        if (original.right - newWidth < imageRect.left) {
          newWidth = original.right - imageRect.left;
          newHeight = newWidth / aspectRatio;
        }
        return Rect.fromLTRB(
          original.right - newWidth,
          original.top,
          original.right,
          original.top + newHeight,
        );
      }
    }
  }

  /// correct [Rect] not to exceed [Rect] of image.
  Rect correct(Rect rect, Rect imageRect) {
    return Rect.fromLTRB(
      max(rect.left, imageRect.left),
      max(rect.top, imageRect.top),
      min(rect.right, imageRect.right),
      min(rect.bottom, imageRect.bottom),
    );
  }
}

class _HorizontalCalculator extends _Calculator {
  const _HorizontalCalculator(this.statusBarHeight) : super(_Calculator);
  final statusBarHeight;

  @override
  Rect imageRect(Size screenSize, double imageRatio) {
    final imageScreenHeight = screenSize.width / imageRatio;
    final top = (screenSize.height - appBarHeight - imageScreenHeight) / 2;
    final bottom = top + imageScreenHeight;
    return Rect.fromLTWH(0, top, screenSize.width, bottom - top);
  }

  @override
  Rect initialCropRect(
      Size screenSize, Rect imageRect, double aspectRatio, double sizeRatio) {
    final imageRatio = imageRect.width / imageRect.height;
    final imageScreenHeight = screenSize.width / imageRatio;

    final initialSize = imageRatio > aspectRatio
        ? Size((imageScreenHeight * aspectRatio) * sizeRatio,
            imageScreenHeight * sizeRatio)
        : Size(screenSize.width * sizeRatio,
            (screenSize.width / aspectRatio) * sizeRatio);

    return Rect.fromLTWH(
      (screenSize.width - initialSize.width) / 2,
      (screenSize.height - appBarHeight - initialSize.height) / 2,
      initialSize.width,
      initialSize.height,
    );
  }

  @override
  double screenSizeRatio(image.Image targetImage, Size screenSize) {
    print('AR::: width ratio ${targetImage.width / screenSize.width}');
    return targetImage.width / screenSize.width;
    // return 1;
  }
}

class _VerticalCalculator extends _Calculator {
  const _VerticalCalculator(this.statusBarHeight) : super(_Calculator);
  final statusBarHeight;

  @override
  Rect imageRect(Size screenSize, double imageRatio) {
    final imageScreenWidth = (screenSize.height - appBarHeight) * imageRatio;
    final left = (screenSize.width - imageScreenWidth) / 2;
    final right = left + imageScreenWidth;
    return Rect.fromLTWH(left, 0, right - left, screenSize.height - appBarHeight);
  }

  @override
  Rect initialCropRect(
      Size screenSize, Rect imageRect, double aspectRatio, double sizeRatio) {
    final imageRatio = imageRect.width / imageRect.height;
    final imageScreenWidth = screenSize.height - appBarHeight * imageRatio;

    final initialSize = imageRatio < aspectRatio
        ? Size(imageScreenWidth * sizeRatio,
            imageScreenWidth / aspectRatio * sizeRatio)
        : Size(((screenSize.height - appBarHeight) * aspectRatio) * sizeRatio,
            (screenSize.height - appBarHeight) * sizeRatio);

    return Rect.fromLTWH(
      (screenSize.width - initialSize.width) / 2,
      ((screenSize.height - appBarHeight) - initialSize.height) / 2,
      initialSize.width,
      initialSize.height,
    );
  }

  @override
  double screenSizeRatio(image.Image targetImage, Size screenSize) {
    print('AR::: height ratio ${targetImage.height / (screenSize.height - appBarHeight)}');

    return targetImage.height / (screenSize.height - appBarHeight);
    // return targetImage.height / (screenSize.height);
  }
}
