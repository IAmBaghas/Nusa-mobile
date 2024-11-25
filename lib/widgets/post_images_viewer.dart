import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'article_sections/image_viewer.dart';

class PostImagesViewer extends StatelessWidget {
  final List<Map<String, dynamic>> images;

  const PostImagesViewer({
    super.key,
    required this.images,
  });

  String _getImageUrl(Map<String, dynamic> image) {
    final filePath = image['file'] as String;
    if (filePath.isEmpty) return '';

    final baseUrl =
        Platform.isAndroid ? 'http://10.0.2.2:5000' : 'http://localhost:5000';
    final fullUrl = '$baseUrl/uploads/$filePath';

    print('PostImagesViewer - Image URL: $fullUrl'); // Debug log
    return fullUrl;
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    // Single image
    if (images.length == 1) {
      final imageUrl = _getImageUrl(images[0]);
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageViewer(
                  imageUrls: [imageUrl],
                  initialIndex: 0,
                ),
              ),
            );
          },
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) {
              print('Error loading image: $error, URL: $url');
              return Container(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: const Icon(Icons.error),
              );
            },
          ),
        ),
      );
    }

    // Multiple images
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.count(
        crossAxisCount: images.length == 2 ? 2 : 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        physics: const NeverScrollableScrollPhysics(),
        children: images.asMap().entries.map((entry) {
          final index = entry.key;
          final image = entry.value;
          final imageUrl = _getImageUrl(image);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageViewer(
                    imageUrls: images.map((img) => _getImageUrl(img)).toList(),
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) {
                print('Error loading image: $error, URL: $url');
                return Container(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: const Icon(Icons.error),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
