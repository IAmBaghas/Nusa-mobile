import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/custom_app_bar.dart';
import '../services/siswa_posts_service.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import '../widgets/image_cropper_dialog.dart';
import '../screens/profile_screen.dart';
import '../screens/main_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _siswaPostsService = SiswaPostsService();
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  List<File> _selectedImages = [];

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return;

      // Convert XFile to Uint8List for cropping
      final File imageFile = File(image.path);
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Show cropping dialog
      final croppedBytes = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageCropperDialog(
            image: imageBytes,
            isCircular: false,
          ),
        ),
      );

      if (croppedBytes == null) return;

      // Save cropped image to temporary file with unique name
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/cropped_image_$timestamp.jpg');
      await tempFile.writeAsBytes(croppedBytes);

      setState(() {
        _selectedImages.add(tempFile);
      });
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih foto: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih minimal satu foto'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final caption = _captionController.text.trim();
      print('Submitting post with caption: "$caption"');
      print('Selected images count: ${_selectedImages.length}');

      setState(() => _isLoading = true);

      try {
        // Get user data for profile ID
        final userData = await _siswaPostsService.getUserData();
        if (userData == null) {
          throw Exception('User data not found');
        }

        final success = await _siswaPostsService.createPost(
          caption,
          _selectedImages,
        );

        if (!mounted) return;

        if (success) {
          // Clear form and loading state before navigation
          setState(() {
            _isLoading = false;
            _selectedImages.clear();
            _captionController.clear();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post berhasil dibuat'),
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        print('Error submitting post: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal membuat post: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      print('Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: CustomAppBar(
        showLogo: false,
        title: 'Upload',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selected Images Grid
            if (_selectedImages.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    return _buildAddButton(colorScheme, textTheme);
                  }
                  return _buildImageTile(index, colorScheme);
                },
              )
            else
              // Initial Add Image Button
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tambah Foto',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),
            // Caption Input
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: _captionController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Masukan Caption...',
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                  counter: const SizedBox.shrink(),
                ),
                onChanged: (value) {
                  // Trigger validation on change
                  _formKey.currentState?.validate();
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Keterangan tidak boleh kosong';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 16),
            // Upload Guidelines
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panduan Unggah',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildGuidelineItem(
                    context,
                    'Gunakan foto yang jelas dan relevan',
                  ),
                  _buildGuidelineItem(
                    context,
                    'Berikan keterangan yang informatif',
                  ),
                  _buildGuidelineItem(
                    context,
                    'Hormati hak cipta dan privasi orang lain',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _isLoading ? null : _handleSubmit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Unggah'),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: _selectedImages.length >= 10 ? null : _pickImage,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: _selectedImages.length >= 10
                  ? colorScheme.outline
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              'Tambah',
              style: textTheme.labelSmall?.copyWith(
                color: _selectedImages.length >= 10
                    ? colorScheme.outline
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            if (_selectedImages.length >= 10)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Maksimal 10 foto',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.error,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(int index, ColorScheme colorScheme) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.file(
              _selectedImages[index],
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton.filled(
            onPressed: () => _removeImage(index),
            icon: const Icon(Icons.close, size: 16),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              padding: const EdgeInsets.all(4),
              minimumSize: const Size(24, 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuidelineItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
