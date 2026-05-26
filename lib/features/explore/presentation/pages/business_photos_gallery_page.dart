import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Full-screen photo grid for a business. Tapping a thumbnail opens a
/// zoomable viewer with swipe between photos.
class BusinessPhotosGalleryPage extends StatelessWidget {
  const BusinessPhotosGalleryPage({
    super.key,
    required this.businessName,
    required this.photos,
  });

  final String businessName;
  final List<String> photos;

  bool _isNetwork(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

  Widget _buildThumb(String url) {
    if (_isNetwork(url)) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.backgroundGrey,
        child: const Icon(Icons.image_outlined, color: AppColors.textTertiary),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(businessName.isEmpty ? 'Photos' : '$businessName • Photos'),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: photos.isEmpty
          ? Center(
              child: Text(
                'No photos available.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => _BusinessPhotoViewerPage(
                          photos: photos,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildThumb(photos[index]),
                  ),
                );
              },
            ),
    );
  }
}

class _BusinessPhotoViewerPage extends StatefulWidget {
  const _BusinessPhotoViewerPage({
    required this.photos,
    required this.initialIndex,
  });

  final List<String> photos;
  final int initialIndex;

  @override
  State<_BusinessPhotoViewerPage> createState() =>
      _BusinessPhotoViewerPageState();
}

class _BusinessPhotoViewerPageState extends State<_BusinessPhotoViewerPage> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isNetwork(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${_index + 1} / ${widget.photos.length}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, index) {
          final url = widget.photos[index];
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: _isNetwork(url)
                  ? Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 64,
                      ),
                    )
                  : Image.asset(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
