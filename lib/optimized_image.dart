import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'cache_manager.dart';

/// Optimized image widget with advanced caching and progressive loading
class OptimizedCachedImage extends StatelessWidget {
  const OptimizedCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.useFullQuality = false,
    this.allowOptimization = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
    this.cacheManager,
    this.enableProgressiveLoading = true,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool useFullQuality;
  final bool allowOptimization;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;
  final CacheManager? cacheManager;
  final bool enableProgressiveLoading;

  bool _isSvgUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    
    final path = uri.path.toLowerCase();
    if (path.endsWith('.svg')) return true;
    
    final format = uri.queryParameters['format']?.toLowerCase();
    if (format == 'svg') return true;
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Handle SVG images
    if (_isSvgUrl(imageUrl)) {
      return SvgPicture.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (context) => _buildPlaceholder(context),
      );
    }

    // Use custom cache manager for better performance
    final effectiveCacheManager = cacheManager ?? VHBCImageCacheManager.instance;

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: effectiveCacheManager,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: maxWidthDiskCache,
      maxHeightDiskCache: maxHeightDiskCache,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      placeholder: enableProgressiveLoading
          ? (context, url) => _buildProgressivePlaceholder(context)
          : (placeholder != null ? (context, url) => placeholder! : null),
      errorWidget: (context, url, error) => _buildErrorWidget(context),
      // Use explicit cache key for better cache hits
      cacheKey: imageUrl,
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) return placeholder!;
    
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF4F7FB),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildProgressivePlaceholder(BuildContext context) {
    if (placeholder != null) return placeholder!;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Shimmer effect
          Positioned.fill(
            child: _ShimmerEffect(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey[300]!,
                      Colors.grey[100]!,
                      Colors.grey[300]!,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Loading indicator
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F88D5)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorWidget != null) return errorWidget!;
    
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF4F7FB),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.broken_image,
            color: Color(0xFF6C7A89),
            size: 32,
          ),
          SizedBox(height: 4),
          Text(
            'Failed to load',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF6C7A89),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer effect for progressive loading
class _ShimmerEffect extends StatefulWidget {
  const _ShimmerEffect({required this.child});

  final Widget child;

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Colors.transparent,
                Colors.white24,
                Colors.transparent,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
