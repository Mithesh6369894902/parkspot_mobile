import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/land.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../utils/helpers.dart';
import 'land_detail_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  List<Land> _lands = [];
  bool _loading = true;
  String? _error;
  LatLng _center = const LatLng(20.5937, 78.9629);
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        _center = LatLng(pos.latitude, pos.longitude);
        _mapController.move(_center, 12);
      }
    } catch (e) {
      // Location not available, use default center
    }
    _fetchLands();
  }

  Future<void> _fetchLands() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/lands?lat=${_center.latitude}&lng=${_center.longitude}&radius=5000');
      setState(() {
        _lands = (res['lands'] as List).map((l) => Land.fromJson(l)).toList();
        _loading = false;
      });
      if (_lands.isNotEmpty) {
        _fitMapToMarkers();
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Server is waking up. Tap refresh to try again.';
      });
    }
  }

  void _fitMapToMarkers() {
    if (_lands.isEmpty) return;
    double minLat = _lands.first.lat, maxLat = _lands.first.lat;
    double minLng = _lands.first.lng, maxLng = _lands.first.lng;
    for (var land in _lands) {
      if (land.lat < minLat) minLat = land.lat;
      if (land.lat > maxLat) maxLat = land.lat;
      if (land.lng < minLng) minLng = land.lng;
      if (land.lng > maxLng) maxLng = land.lng;
    }
    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final screens = [
      _buildMapScreen(auth),
      const MyBookingsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: const Color(0xFF059669),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildMapScreen(AuthProvider auth) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.local_parking, color: Color(0xFF059669), size: 20),
            ),
            const SizedBox(width: 8),
            const Text('ParkSpot', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchLands, tooltip: 'Refresh'),
          if (auth.user?.role == 'owner')
            IconButton(icon: const Icon(Icons.add_location), tooltip: 'List Land',
              onPressed: () {/* TODO: navigate to list land */}),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _center, initialZoom: 5),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.parkspot',
              ),
              MarkerLayer(markers: _lands.map((land) => Marker(
                point: LatLng(land.lat, land.lng),
                width: 90, height: 45,
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LandDetailScreen(land: land))),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Text('Rs.${land.pricePerHour.toInt()}/hr',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      Icon(Icons.location_on, color: const Color(0xFF059669), size: 20),
                    ],
                  ),
                ),
              )).toList()),
            ],
          ),
          // Top search bar
          Positioned(
            top: 12, left: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    _error != null ? _error! : _loading ? 'Loading parking lands...' : '${_lands.length} parking lands available',
                    style: TextStyle(color: _error != null ? Colors.red : Colors.grey, fontSize: 14),
                  )),
                  if (_error != null)
                    IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF059669)), onPressed: _fetchLands),
                ],
              ),
            ),
          ),
          // Bottom land cards
          Positioned(
            bottom: 12, left: 12, right: 12,
            child: SizedBox(
              height: 130,
              child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
                : _lands.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_error != null ? Icons.error_outline : Icons.local_parking,
                            color: Colors.grey, size: 32),
                          const SizedBox(height: 8),
                          Text(_error ?? 'No parking lands found', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _lands.length,
                      itemBuilder: (ctx, i) => _landCard(_lands[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _landCard(Land land) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LandDetailScreen(land: land))),
      child: Container(
        width: 280, margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.local_parking, color: Color(0xFF059669), size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(land.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text('${land.city}, ${land.state}', style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rs.${land.pricePerHour.toInt()}/hr',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669), fontSize: 15)),
                    Text('${land.totalSpots} spots available',
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Book Now', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
