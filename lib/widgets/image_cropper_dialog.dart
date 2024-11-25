import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

class ImageCropperDialog extends StatefulWidget {
  final Uint8List image;
  final bool isCircular;

  const ImageCropperDialog({
    Key? key,
    required this.image,
    this.isCircular = true,
  }) : super(key: key);

  @override
  State<ImageCropperDialog> createState() => _ImageCropperDialogState();
}

class _ImageCropperDialogState extends State<ImageCropperDialog> {
  final _cropKey = GlobalKey();
  double _scale = 1.0;
  Offset _position = Offset.zero;
  late ui.Image _sourceImage;
  bool _isImageLoaded = false;
  static const double _minScale = 0.5;
  static const double _maxScale = 3.0;
  static const double _cropSize = 300.0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.image);
    final frame = await codec.getNextFrame();
    setState(() {
      _sourceImage = frame.image;
      _isImageLoaded = true;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta / _scale;
    });
  }

  void _updateScale(double scale) {
    setState(() {
      final prevScale = _scale;
      _scale = scale;
      _position = _position * (prevScale / scale);
    });
  }

  Future<Uint8List?> _cropImage() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true;

      final clipPath = Path();
      if (widget.isCircular) {
        clipPath.addOval(Rect.fromLTWH(0, 0, _cropSize, _cropSize));
      } else {
        clipPath.addRect(Rect.fromLTWH(0, 0, _cropSize, _cropSize));
      }
      canvas.clipPath(clipPath);

      final imageWidth = _sourceImage.width.toDouble();
      final imageHeight = _sourceImage.height.toDouble();
      final imageAspectRatio = imageWidth / imageHeight;

      double scaledWidth, scaledHeight;
      if (imageAspectRatio > 1) {
        scaledHeight = _cropSize;
        scaledWidth = scaledHeight * imageAspectRatio;
      } else {
        scaledWidth = _cropSize;
        scaledHeight = scaledWidth / imageAspectRatio;
      }

      final matrix = Matrix4.identity()
        ..translate(_cropSize / 2, _cropSize / 2)
        ..scale(_scale)
        ..translate(_position.dx, _position.dy)
        ..translate(-scaledWidth / 2, -scaledHeight / 2);

      canvas.transform(matrix.storage);

      canvas.drawImageRect(
        _sourceImage,
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
        Rect.fromLTWH(0, 0, scaledWidth, scaledHeight),
        paint,
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(_cropSize.toInt(), _cropSize.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error cropping image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesuaikan Foto'),
        actions: [
          TextButton(
            onPressed: () async {
              final croppedImage = await _cropImage();
              if (croppedImage != null && mounted) {
                Navigator.pop(context, croppedImage);
              }
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
      body: !_isImageLoaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: _cropSize,
                      height: _cropSize,
                      decoration: BoxDecoration(
                        shape: widget.isCircular
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                        borderRadius:
                            widget.isCircular ? null : BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: widget.isCircular
                            ? BorderRadius.circular(_cropSize / 2)
                            : BorderRadius.circular(8),
                        child: GestureDetector(
                          onPanUpdate: _handlePanUpdate,
                          child: Container(
                            key: _cropKey,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..scale(_scale)
                                ..translate(_position.dx, _position.dy),
                              child: Image.memory(
                                widget.image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: colorScheme.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.zoom_out),
                          Expanded(
                            child: Slider(
                              value: _scale,
                              min: _minScale,
                              max: _maxScale,
                              onChanged: _updateScale,
                              activeColor: colorScheme.primary,
                            ),
                          ),
                          const Icon(Icons.zoom_in),
                        ],
                      ),
                      Text(
                        'Geser untuk mengatur posisi',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
