import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});
  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<Booking> _bookings = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/bookings/my');
      setState(() {
        _bookings = (res['bookings'] as List).map((b) => Booking.fromJson(b)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'all' ? _bookings : _bookings.where((b) => b.status == _filter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: ['all', 'pending', 'confirmed', 'completed', 'cancelled'].map((s) =>
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s[0].toUpperCase() + s.substring(1)),
                    selected: _filter == s,
                    onSelected: (v) => setState(() => _filter = s),
                    selectedColor: const Color(0xFF059669),
                    labelStyle: TextStyle(color: _filter == s ? Colors.white : Colors.grey),
                  ),
                )).toList(),
            ),
          ),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.book_online, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No bookings found', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ]))
                : RefreshIndicator(onRefresh: _fetchBookings,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _bookingCard(filtered[i]),
                    )),
          ),
        ],
      ),
    );
  }

  Widget _bookingCard(Booking b) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(b.landTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor(b.status).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(b.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor(b.status))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(b.landAddress, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${formatDateTime(b.startDate)} - ${formatDateTime(b.endDate)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Text('${b.vehicleType.replaceAll('_', ' ')} x${b.vehicleCount}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Spacer(),
              Text('Rs.${b.totalAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669))),
            ]),
          ],
        ),
      ),
    );
  }
}
