import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

String formatDateTime(DateTime dt) => DateFormat('MMM dd, yyyy hh:mm a').format(dt);
String formatDate(DateTime dt) => DateFormat('MMM dd, yyyy').format(dt);
String formatCurrency(double amount) => 'Rs.${amount.toInt()}';

Color statusColor(String status) {
  switch (status) {
    case 'pending': return Colors.orange;
    case 'confirmed': return Colors.blue;
    case 'active': return Colors.green;
    case 'completed': return Colors.grey;
    case 'cancelled': return Colors.red;
    case 'approved': return Colors.green;
    case 'rejected': return Colors.red;
    default: return Colors.grey;
  }
}
