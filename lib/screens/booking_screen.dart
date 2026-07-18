import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/land.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../utils/helpers.dart';

class BookingScreen extends StatefulWidget {
  final Land land;
  const BookingScreen({super.key, required this.land});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _startDate = DateTime.now().add(const Duration(hours: 1));
  DateTime _endDate = DateTime.now().add(const Duration(hours: 5));
  String _vehicleType = 'four_wheeler';
  int _vehicleCount = 1;
  bool _loading = false;
  late Razorpay _razorpay;
  String? _currentBookingId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await ApiService.post('/payments/verify', {
        'razorpayOrderId': response.orderId ?? '',
        'razorpayPaymentId': response.paymentId ?? '',
        'razorpaySignature': response.signature ?? '',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful! Booking confirmed!'), backgroundColor: Colors.green));
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment verified but error: $e'), backgroundColor: Colors.orange));
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message ?? "Unknown error"}'), backgroundColor: Colors.red));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet: ${response.walletName}')));
  }

  int get _hours => _endDate.difference(_startDate).inHours.clamp(1, 168);
  double get _total => widget.land.pricePerHour * _hours * _vehicleCount;

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate));
      if (time != null) {
        final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        setState(() {
          if (isStart) {
            _startDate = dt;
            if (_endDate.isBefore(_startDate.add(const Duration(hours: 1)))) {
              _endDate = _startDate.add(const Duration(hours: 1));
            }
          } else {
            _endDate = dt;
          }
        });
      }
    }
  }

  Future<void> _book() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book')));
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')));
      return;
    }

    setState(() => _loading = true);
    try {
      // Step 1: Create booking
      final res = await ApiService.post('/bookings', {
        'landId': widget.land.id,
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate.toIso8601String(),
        'vehicleType': _vehicleType,
        'vehicleCount': _vehicleCount,
      });
      final bookingId = res['booking']['_id'];

      // Step 2: Create payment order
      final orderRes = await ApiService.post('/payments/create-order', {
        'bookingId': bookingId,
      });
      final orderId = orderRes['order']['id'];
      final key = orderRes['key'];

      // Step 3: Open Razorpay checkout
      var options = {
        'key': key,
        'amount': (_total * 100).toInt(),
        'name': 'ParkSpot',
        'description': 'Parking at ${widget.land.title}',
        'order_id': orderId,
        'prefill': {
          'contact': auth.user?.phone ?? '',
          'email': auth.user?.email ?? '',
        },
        'theme': {'color': '#059669'},
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Parking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Land info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.local_parking, color: Color(0xFF059669))),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.land.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.land.address, style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('Select Date & Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _dateTile('Start', _startDate, () => _pickDate(true))),
              const SizedBox(width: 12),
              Expanded(child: _dateTile('End', _endDate, () => _pickDate(false))),
            ]),
            const SizedBox(height: 20),
            const Text('Vehicle Type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _vehicleBtn('Four Wheeler', 'four_wheeler', Icons.directions_car)),
              const SizedBox(width: 12),
              Expanded(child: _vehicleBtn('Two Wheeler', 'two_wheeler', Icons.two_wheeler)),
            ]),
            const SizedBox(height: 20),
            const Text('Number of Vehicles', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              IconButton(
                onPressed: _vehicleCount > 1 ? () => setState(() => _vehicleCount--) : null,
                icon: const Icon(Icons.remove_circle_outline, size: 32)),
              const SizedBox(width: 16),
              Text('$_vehicleCount', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => setState(() => _vehicleCount++),
                icon: const Icon(Icons.add_circle, color: Color(0xFF059669), size: 32)),
            ]),
            const SizedBox(height: 24),
            // Price summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                _priceRow('Base Rate', 'Rs.${widget.land.pricePerHour.toInt()}/hr'),
                _priceRow('Duration', '$_hours hours'),
                _priceRow('Vehicles', 'x$_vehicleCount'),
                const Divider(height: 20),
                _priceRow('Total Amount', 'Rs.${_total.toInt()}', bold: true),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _book,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.payment, size: 20),
                        const SizedBox(width: 8),
                        Text('Pay Rs.${_total.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Secure payment via Razorpay', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['UPI', 'GPay', 'Paytm', 'Cards', 'Net Banking'].map((m) =>
                Chip(label: Text(m, style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.grey.shade100, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTile(String label, DateTime dt, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(formatDateTime(dt), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _vehicleBtn(String label, String value, IconData icon) {
    final selected = _vehicleType == value;
    return GestureDetector(
      onTap: () => setState(() => _vehicleType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE0F2F1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF059669) : Colors.grey.shade300, width: 2),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? const Color(0xFF059669) : Colors.grey, size: 28),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF059669) : Colors.grey, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.grey, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: bold ? 20 : 14, color: bold ? const Color(0xFF059669) : null)),
      ]),
    );
  }
}
