import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/land.dart';
import '../utils/helpers.dart';
import 'booking_screen.dart';

class LandDetailScreen extends StatelessWidget {
  final Land land;
  const LandDetailScreen({super.key, required this.land});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200, pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(land.title, style: const TextStyle(fontSize: 16)),
              background: land.images.isNotEmpty
                ? Image.network(land.images.first, fit: BoxFit.cover)
                : Container(color: const Color(0xFFE0F2F1),
                    child: const Icon(Icons.local_parking, size: 80, color: Color(0xFF059669))),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF059669), size: 18),
                      const SizedBox(width: 4),
                      Expanded(child: Text('${land.address}, ${land.city}, ${land.state}',
                        style: const TextStyle(color: Colors.grey))),
                    ],
                  ),
                  if (land.averageRating > 0) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      Text(' ${land.averageRating} (${land.reviewCount} reviews)'),
                    ]),
                  ],
                  const SizedBox(height: 20),
                  _sectionTitle('Parking Capacity'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _capacityCard(Icons.directions_car, '${land.fourWheelerSpots}', 'Four Wheeler', Colors.blue),
                      const SizedBox(width: 12),
                      _capacityCard(Icons.two_wheeler, '${land.twoWheelerSpots}', 'Two Wheeler', Colors.green),
                      const SizedBox(width: 12),
                      _capacityCard(Icons.square_foot, '${land.areaSqFt.toInt()}', 'Area (sqft)', const Color(0xFF059669)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('About'),
                  const SizedBox(height: 8),
                  Text(land.description, style: const TextStyle(color: Colors.grey, height: 1.5)),
                  if (land.amenities.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _sectionTitle('Amenities'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: land.amenities.map((a) => Chip(
                        label: Text(a, style: const TextStyle(fontSize: 12)),
                        backgroundColor: const Color(0xFFE0F2F1),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _sectionTitle('Location'),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 200,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(land.lat, land.lng),
                          initialZoom: 15, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                        ),
                        children: [
                          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.parkspot'),
                          MarkerLayer(markers: [Marker(point: LatLng(land.lat, land.lng), width: 40, height: 40,
                            child: const Icon(Icons.location_pin, color: Color(0xFF059669), size: 40))]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rs.${land.pricePerHour.toInt()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                const Text('per hour', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(land: land))),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Book Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));

  Widget _capacityCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ),
    );
  }
}
