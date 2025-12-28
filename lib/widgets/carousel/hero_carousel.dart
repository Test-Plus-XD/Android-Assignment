/// Hero Carousel Widget
///
/// Full-width hero image carousel with auto-play and page indicators.
/// Optimized for Android with Material Design components.

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../common/loading_indicator.dart';

class HeroCarouselItem {
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final VoidCallback? onTap;

  const HeroCarouselItem({
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.onTap,
  });
}

class HeroCarousel extends StatefulWidget {
  final List<HeroCarouselItem> items;
  final double height;
  final Duration autoPlayInterval;
  final bool autoPlay;
  final bool showIndicator;
  final bool showOverlay;
  final EdgeInsets padding;

  const HeroCarousel({
    super.key,
    required this.items,
    this.height = 300.0,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.autoPlay = true,
    this.showIndicator = true,
    this.showOverlay = true,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      );
    }

    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          // Carousel
          CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: widget.items.length,
            itemBuilder: (context, index, realIndex) {
              final item = widget.items[index];
              return _buildCarouselItem(item);
            },
            options: CarouselOptions(
              height: widget.height,
              viewportFraction: 1.0,
              autoPlay: widget.autoPlay,
              autoPlayInterval: widget.autoPlayInterval,
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: false,
              scrollDirection: Axis.horizontal,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),

          // Page Indicator
          if (widget.showIndicator && widget.items.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: AnimatedSmoothIndicator(
                activeIndex: _currentIndex,
                count: widget.items.length,
                effect: WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: Theme.of(context).colorScheme.primary,
                  dotColor: Theme.of(context).colorScheme.outline,
                ),
                onDotClicked: (index) {
                  _carouselController.animateToPage(index);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCarouselItem(HeroCarouselItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          CachedNetworkImage(
            imageUrl: item.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const CenteredLoadingIndicator(),
            ),
            errorWidget: (context, url, error) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.broken_image,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),

          // Gradient Overlay (for better text readability)
          if (widget.showOverlay && (item.title != null || item.subtitle != null))
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.title != null)
                      Text(
                        item.title!,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                const Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 4,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              shadows: [
                                const Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 4,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
