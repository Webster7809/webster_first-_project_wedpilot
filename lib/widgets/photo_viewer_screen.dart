import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Full-screen, pinch-to-zoom viewer for a list of photo URLs — opened by
/// tapping any vendor thumbnail. Swipes between photos at full width and
/// zooms each one individually via [InteractiveViewer]; resets to fit-width
/// whenever the visible photo changes so a zoomed-in state doesn't carry
/// over to the next swipe.
///
/// Pass full-resolution URLs here, not the small ones used for a grid
/// thumbnail — a 300px-wide thumbnail still looks soft blown up to full
/// screen no matter how it's rendered.
class PhotoViewerScreen extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final String heroLabel;

  const PhotoViewerScreen({
    super.key,
    required this.urls,
    this.initialIndex = 0,
    this.heroLabel = 'Photo',
  });

  static void open(
    BuildContext context, {
    required List<String> urls,
    int initialIndex = 0,
    String heroLabel = 'Photo',
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) =>
            FadeTransition(
          opacity: animation,
          child: PhotoViewerScreen(
            urls: urls,
            initialIndex: initialIndex,
            heroLabel: heroLabel,
          ),
        ),
      ),
    );
  }

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => InteractiveViewer(
              // A fresh key per page so InteractiveViewer's internal zoom
              // transform resets to fit-width on swipe, instead of keeping
              // whatever zoom level the previous photo was left at.
              key: ValueKey(i),
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Semantics(
                  image: true,
                  label: '${widget.heroLabel} ${i + 1} of ${widget.urls.length}',
                  child: CachedNetworkImage(
                    imageUrl: widget.urls[i],
                    fit: BoxFit.contain,
                    fadeInDuration: const Duration(milliseconds: 200),
                    placeholder: (_, _) => const SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    errorWidget: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Material(
                      color: Colors.black.withAlpha(140),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    if (widget.urls.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_index + 1} / ${widget.urls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
