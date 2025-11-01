import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'models.dart';

// Restaurant detail page.
class RestaurantDetailPage extends StatelessWidget {
  final Restaurant restaurant;
  final bool isTraditionalChinese;
  const RestaurantDetailPage({required this.restaurant, this.isTraditionalChinese = false, super.key});

  @override
  Widget build(BuildContext context) {
    final String displayName = isTraditionalChinese ? restaurant.nameTc : restaurant.nameEn;
    final String address = isTraditionalChinese ? restaurant.addressTc : restaurant.addressEn;
    final String district = isTraditionalChinese ? restaurant.districtTc : restaurant.districtEn;
    final String keywords = isTraditionalChinese ? restaurant.keywordTc.join(', ') : restaurant.keywordEn.join(', ');

    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: ListView(
        children: [
          Image.asset(restaurant.image, height: 240, fit: BoxFit.cover),
          Padding(padding: const EdgeInsets.all(12.0), child: Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          ListTile(leading: const Icon(Icons.location_on), title: Text(address)),
          ListTile(leading: const Icon(Icons.map), title: Text('${isTraditionalChinese ? '地區' : 'District'}: $district')),
          ListTile(leading: const Icon(Icons.label), title: Text('${isTraditionalChinese ? '關鍵字' : 'Keywords'}: $keywords')),
          SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(restaurant.latitude, restaurant.longitude),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId(restaurant.nameEn),
                  position: LatLng(restaurant.latitude, restaurant.longitude),
                  infoWindow: InfoWindow(title: displayName),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
