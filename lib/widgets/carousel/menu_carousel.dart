/// Menu Carousel Widget
///
/// Carousel for displaying menu item images.
/// Optimized for Android with Material Design components.

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models.dart';

class MenuCarousel extends StatefulWidget {
  final List<MenuItem> menuItems;
  final bool isTraditionalChinese;
  final void Function(MenuItem)? onMenuItemTap;
  final double height;
  final bool showIndicator;
  final bool showPrice;
  final EdgeInsets padding;

  const MenuCarousel({
    super.key,
    required this.menuItems,
    this.isTraditionalChinese = false,
    this.onMenuItemTap,
    this.height = 200.0,
    this.showIndicator = true,
    this.showPrice = true,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
  });

  @override
  State<MenuCarousel> createState() => _MenuCarouselState();
}

class _MenuCarouselState extends State<MenuCarousel> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    if (widget.menuItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          // Carousel
          CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: widget.menuItems.length,
            itemBuilder: (context, index, realIndex) {
              final menuItem = widget.menuItems[index];
              return _buildMenuItemCard(context, menuItem);
            },
            options: CarouselOptions(
              height: widget.height,
              viewportFraction: 0.8,
              autoPlay: false,
              enlargeCenterPage: true,
              enlargeFactor: 0.2,
              scrollDirection: Axis.horizontal,
              padEnds: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),

          // Page Indicator
          if (widget.showIndicator && widget.menuItems.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: AnimatedSmoothIndicator(
                activeIndex: _currentIndex,
                count: widget.menuItems.length,
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

  Widget _buildMenuItemCard(BuildContext context, MenuItem menuItem) {
    final name = widget.isTraditionalChinese
        ? (menuItem.nameTc ?? menuItem.nameEn ?? '')
        : (menuItem.nameEn ?? '');

    return GestureDetector(
      onTap: () => widget.onMenuItemTap?.call(menuItem),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Menu Item Image
            CachedNetworkImage(
              imageUrl: menuItem.image ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.restaurant_menu,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),

            // Gradient Overlay
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
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Menu Item Name
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Price and Availability
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        if (widget.showPrice && menuItem.price != null)
                          Text(
                            'HK\$${menuItem.price!.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),

                        // Availability Badge
                        if (menuItem.available == false)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.isTraditionalChinese ? '已售罄' : 'Sold Out',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                      ],
                    ),

                    // Category
                    if (menuItem.category != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          menuItem.category!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
