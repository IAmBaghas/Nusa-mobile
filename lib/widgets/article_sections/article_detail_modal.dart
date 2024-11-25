import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import '../../models/article.dart';
import 'image_viewer.dart';

class ArticleDetailModal extends StatelessWidget {
  final Article article;

  const ArticleDetailModal({
    super.key,
    required this.article,
  });

  void _showImageViewer(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewer(
          imageUrls: article.fullGalleryImages,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _handleLink(BuildContext context, String url, String text) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Buka Link',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda ingin membuka link ini?',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                url,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link disalin ke clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Salin Link'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final uri = Uri.parse(url);
                await launchUrl(
                  uri,
                  mode: LaunchMode.inAppWebView,
                  webViewConfiguration: const WebViewConfiguration(
                    enableJavaScript: true,
                    enableDomStorage: true,
                  ),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                debugPrint('Error launching URL: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tidak dapat membuka link: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Buka Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 500) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        bottomNavigationBar: Container(
          color: colorScheme.surface,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            top: 16,
          ),
          child: FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Tutup'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
        body: Container(
          color: colorScheme.surface,
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Main content
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // App bar with image
                    SliverAppBar(
                      expandedHeight: 300,
                      pinned: true,
                      backgroundColor: colorScheme.surface,
                      surfaceTintColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      automaticallyImplyLeading: false,
                      flexibleSpace: FlexibleSpaceBar(
                        background: PageView.builder(
                          itemCount: article.galleryImages.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImageViewer(
                                    imageUrls: article.fullGalleryImages,
                                    initialIndex: index,
                                  ),
                                ),
                              ),
                              child: Hero(
                                tag: 'article-image-${article.id}-$index',
                                child: CachedNetworkImage(
                                  imageUrl: article.fullGalleryImages[index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: colorScheme.surfaceVariant,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) {
                                    debugPrint('Image error: $error');
                                    debugPrint('URL: $url');
                                    return Container(
                                      color: colorScheme.surfaceVariant,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: colorScheme.error,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Gagal memuat gambar',
                                            style:
                                                textTheme.bodySmall?.copyWith(
                                              color: colorScheme.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  httpHeaders: const {
                                    'Accept': 'image/jpeg,image/png,image/jpg',
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Article content
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Category and date
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  article.category,
                                  style: textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                article.formattedFullDate,
                                style: textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Title
                          Text(
                            article.title,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Content
                          _buildFormattedContent(context, article.content),
                          const SizedBox(height: 16),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormattedContent(BuildContext context, String content) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Extract links and replace with markers
    final linkPattern = RegExp(r'<a href="([^"]*)"[^>]*>(.*?)<\/a>');
    final urlPattern = RegExp(r'https?://\S+');

    // First, handle HTML links
    content = content.replaceAllMapped(linkPattern, (match) {
      final url = match.group(1)?.trim() ?? '';
      // Clean up the text content more thoroughly
      final text = match
              .group(2)
              ?.replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim() ??
          url;
      // Use different markers that won't appear in normal text
      return '§§URL§§$url§§TEXT§§$text§§END§§';
    });

    // Then clean up HTML tags and normalize line breaks
    content = content
        .replaceAll(RegExp(r'<p[^>]*>'), '')
        .replaceAll('</p>', '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    // Split content into paragraphs
    final paragraphs =
        content.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: paragraphs.map((paragraph) {
          if (paragraph.trim().isEmpty) {
            return const SizedBox(height: 16);
          }

          // Handle paragraphs with links
          if (paragraph.contains('§§URL§§')) {
            final spans = <TextSpan>[];
            var currentText = paragraph;

            while (currentText.contains('§§URL§§')) {
              final linkStart = currentText.indexOf('§§URL§§');
              if (linkStart > 0) {
                spans.add(TextSpan(
                  text: currentText.substring(0, linkStart),
                  style: textTheme.bodyLarge?.copyWith(
                    height: 1.8,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.3,
                  ),
                ));
              }

              final linkEnd = currentText.indexOf('§§END§§');
              if (linkEnd > linkStart) {
                final linkContent =
                    currentText.substring(linkStart + 7, linkEnd);
                final parts = linkContent.split('§§TEXT§§');
                final url = parts[0].trim();
                final text = parts.length > 1 ? parts[1].trim() : url.trim();

                spans.add(TextSpan(
                  text: text,
                  style: textTheme.bodyLarge?.copyWith(
                    height: 1.8,
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                    letterSpacing: 0.3,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _handleLink(context, url, text),
                ));

                currentText = currentText.substring(linkEnd + 7).trim();
              } else {
                break;
              }
            }

            if (currentText.isNotEmpty) {
              // Handle any remaining URLs in the text
              final urlMatches = urlPattern.allMatches(currentText);
              if (urlMatches.isEmpty) {
                spans.add(TextSpan(
                  text: currentText,
                  style: textTheme.bodyLarge?.copyWith(
                    height: 1.8,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.3,
                  ),
                ));
              } else {
                var lastEnd = 0;
                for (final match in urlMatches) {
                  if (match.start > lastEnd) {
                    spans.add(TextSpan(
                      text: currentText.substring(lastEnd, match.start),
                      style: textTheme.bodyLarge?.copyWith(
                        height: 1.8,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.3,
                      ),
                    ));
                  }

                  final url = match.group(0)!;
                  spans.add(TextSpan(
                    text: url,
                    style: textTheme.bodyLarge?.copyWith(
                      height: 1.8,
                      color: colorScheme.primary,
                      decoration: TextDecoration.underline,
                      letterSpacing: 0.3,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _handleLink(context, url, url),
                  ));

                  lastEnd = match.end;
                }

                if (lastEnd < currentText.length) {
                  spans.add(TextSpan(
                    text: currentText.substring(lastEnd),
                    style: textTheme.bodyLarge?.copyWith(
                      height: 1.8,
                      color: colorScheme.onSurface,
                      letterSpacing: 0.3,
                    ),
                  ));
                }
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 24.0),
              child: SelectableText.rich(
                TextSpan(children: spans),
                textAlign: TextAlign.justify,
              ),
            );
          }

          // Handle regular text paragraphs
          return Container(
            margin: const EdgeInsets.only(bottom: 24.0),
            child: SelectableText(
              paragraph.trim(),
              style: textTheme.bodyLarge?.copyWith(
                height: 1.8,
                color: colorScheme.onSurface,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.justify,
            ),
          );
        }).toList(),
      ),
    );
  }
}
