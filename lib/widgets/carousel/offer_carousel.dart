/// Offer Carousel Widget
///
/// Carousel for displaying promotional offers, deals, or announcements.
/// Optimized for Android with Material Design components.

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OfferItem {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final String? description;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const OfferItem({
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.description,
    this.backgroundColor,
    this.onTap,
  });
}

class OfferCarousel extends StatefulWidget {
  final List<OfferItem> offers;
  final double height;
  final Duration autoPlayInterval;
  final bool autoPlay;
  final bool showIndicator;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const OfferCarousel({
    super.key,
    required this.offers,
    this.height = 180.0,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.autoPlay = true,
    this.showIndicator = true,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  });

  @override
  State<OfferCarousel> createState() => _OfferCarouselState();
}

class _OfferCarouselState extends State<OfferCarousel> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    if (widget.offers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Carousel
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: widget.offers.length,
          itemBuilder: (context, index, realIndex) {
            final offer = widget.offers[index];
            return _buildOfferCard(context, offer);
          },
          options: CarouselOptions(
            height: widget.height,
            viewportFraction: 0.9,
            autoPlay: widget.autoPlay,
            autoPlayInterval: widget.autoPlayInterval,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            enlargeFactor: 0.1,
            scrollDirection: Axis.horizontal,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),

        // Page Indicator
        if (widget.showIndicator && widget.offers.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: AnimatedSmoothIndicator(
              activeIndex: _currentIndex,
              count: widget.offers.length,
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
    );
  }

  Widget _buildOfferCard(BuildContext context, OfferItem offer) {
    return GestureDetector(
      onTap: offer.onTap,
      child: Container(
        margin: widget.margin,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: offer.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: offer.backgroundColor ??
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: offer.backgroundColor ??
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.local_offer,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: widget.padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        offer.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

                      // Subtitle
                      if (offer.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          offer.subtitle!,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Description
                      if (offer.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          offer.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.8),
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

              // "Tap to view" indicator
              if (offer.onTap != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}