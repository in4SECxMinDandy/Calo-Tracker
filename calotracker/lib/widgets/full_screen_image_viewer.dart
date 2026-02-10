// Full Screen Image Viewer
// Displays images in full screen with pinch-to-zoom and swipe gestures
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  late TransformationController _transformationController;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() => _isZoomed = false);
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (_isZoomed) {
      _resetZoom();
    } else {
      // Zoom to 2x at tap position
      final position = details.localPosition;
      final matrix = Matrix4.identity();
      matrix.setEntry(0, 3, -position.dx);
      matrix.setEntry(1, 3, -position.dy);
      matrix.setEntry(0, 0, 2.0);
      matrix.setEntry(1, 1, 2.0);
      matrix.setEntry(2, 2, 2.0);
      matrix.setEntry(0, 3, matrix.entry(0, 3) + position.dx / 2);
      matrix.setEntry(1, 3, matrix.entry(1, 3) + position.dy / 2);
      _transformationController.value = matrix;
      setState(() => _isZoomed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: widget.imageUrls.length > 1
            ? Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              )
            : null,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.share, color: Colors.white),
            onPressed: () {
              // Share current image URL
              // Share.share(widget.imageUrls[_currentIndex]);
            },
          ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          // Swipe down to dismiss
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            Navigator.pop(context);
          }
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.imageUrls.length,
          physics: _isZoomed
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          onPageChanged: (index) {
            _resetZoom();
            setState(() => _currentIndex = index);
          },
          itemBuilder: (context, index) {
            return Center(
              child: GestureDetector(
                onDoubleTapDown: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 4.0,
                  onInteractionStart: (_) {
                    setState(() => _isZoomed = true);
                  },
                  onInteractionEnd: (_) {
                    if (_transformationController.value.getMaxScaleOnAxis() <= 1.01) {
                      _resetZoom();
                    }
                  },
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[index],
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.photo,
                            color: Colors.white54,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Không thể tải ảnh',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      // Bottom indicator dots for multiple images
      bottomNavigationBar: widget.imageUrls.length > 1
          ? Container(
              color: Colors.black,
              padding: const EdgeInsets.only(bottom: 32, top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentIndex ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
