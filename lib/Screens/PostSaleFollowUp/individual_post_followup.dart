import 'dart:developer';

import 'package:admin/Controller/post_sale_followup_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class IndividualPostReportPage extends StatelessWidget {
  final Map<String, dynamic> order;

  IndividualPostReportPage({super.key, required this.order});

  // Initialize GetX controller (if not already done elsewhere)
  final controller = Get.put(PostSaleFollowupController());

  // Define a minimalist and professional color palette
  static const Color _primaryColor = Color(
    0xFFD13443,
  ); // A subtle blue for accents
  static const Color _textColor = Color(0xFF303030); // Dark grey for main text
  static const Color _lightTextColor = Color(
    0xFF757575,
  ); // Lighter grey for labels
  static const Color _cardColor =
      Colors.white; // Pure white for card background
  static const Color _backgroundColor = Color(
    0xFFF8F8F8,
  ); // Very light off-white scaffold
  static const Color _dividerColor = Color(
    0xFFEEEEEE,
  ); // Very light grey for dividers
  static const Color _contentBoxColor = Color(
    0xFFFBFBFB,
  ); // Even lighter for text boxes
  static const Color _borderColor = Color(0xFFE0E0E0); // General border color

  @override
  Widget build(BuildContext context) {
    log('Order data: ${order.toString()}');

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Order Details', // Simplified title
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: _textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: _cardColor,
        foregroundColor: _textColor,
        elevation: 1, // Minimal app bar elevation
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildMainOrderDetailsCard(order), // All content in one card
      ),
    );
  }

  /// Builds the single, main card containing all order details.
  Widget _buildMainOrderDetailsCard(Map<String, dynamic> data) {
    return Card(
      color: _cardColor,
      elevation: 2, // Subtle elevation for the main card
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20), // Consistent internal padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Customer Name & Order Status (Header) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['name'] ?? 'Unknown Customer',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                _buildOrderStatusBadge(data['order_status'] ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Order ID: ${data['orderId'] ?? 'N/A'}',
              style: TextStyle(
                fontSize: 13,
                color: _lightTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20), // Spacing after header
            // --- Contact Information ---
            _buildSectionHeader(
              'Contact Info',
              Icons.perm_contact_calendar_outlined,
            ),
            _buildDetailRow(
              Icons.email_outlined,
              'Email',
              data['email'] ?? 'N/A',
            ),
            _buildDetailRow(
              Icons.phone_outlined,
              'Phone',
              data['phone1'] ?? 'N/A',
            ),
            if (data['address'] != null &&
                data['address'].toString().isNotEmpty)
              _buildDetailRow(
                Icons.location_on_outlined,
                'Address',
                data['address'],
              ),
            const SizedBox(height: 20), // Spacing after section
            // --- Order Specifics ---
            _buildSectionHeader('Order Details', Icons.info_outline),
            _buildDetailRow(
              Icons.qr_code_outlined,
              'Product ID',
              data['productID'] ?? 'N/A',
            ),
            _buildDetailRow(
              Icons.format_list_numbered_outlined,
              'Quantity',
              data['nos']?.toString() ?? 'N/A',
            ),
            _buildDetailRow(
              Icons.person_outline,
              'Salesman',
              data['salesman'] ?? 'N/A',
            ),
            _buildDetailRow(
              Icons.handyman_outlined,
              'Maker',
              data['maker'] ?? 'N/A',
            ),
            const SizedBox(height: 20), // Spacing after section
            // --- Timestamps ---
            _buildSectionHeader('Timeline', Icons.calendar_month_outlined),
            _buildDetailRow(
              Icons.event_note_outlined,
              'Created',
              data['createdAt'] != null
                  ? DateFormat(
                      'MMM dd, yyyy, hh:mm a',
                    ).format((data['createdAt']))
                  : 'N/A',
            ),
            if (data['deliveryDate'] != null)
              _buildDetailRow(
                Icons.local_shipping_outlined,
                'Delivered',
                DateFormat(
                  'MMM dd, yyyy, hh:mm a',
                ).format((data['deliveryDate'])),
              ),
            const SizedBox(height: 20), // Spacing after section
            // --- Notes / Description (if any) ---
            if ((data['remark'] != null &&
                    data['remark'].toString().trim().isNotEmpty) ||
                (data['followUpNotes'] != null &&
                    data['followUpNotes'].toString().trim().isNotEmpty))
              _buildSectionHeader(
                'Additional Notes',
                Icons.description_outlined,
              ),

            if (data['remark'] != null &&
                data['remark'].toString().trim().isNotEmpty)
              _buildTextContentRow('Remark', data['remark']),

            if (data['followUpNotes'] != null &&
                data['followUpNotes'].toString().trim().isNotEmpty)
              _buildTextContentRow('Follow-up', data['followUpNotes']),
          ],
        ),
      ),
    );
  }

  /// Builds a minimalist section header within the single card.
  Widget _buildSectionHeader(String title, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: _primaryColor),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
          ],
        ),
        const Divider(
          height: 20,
          thickness: 0.8,
          color: _dividerColor,
        ), // Thinner, lighter divider
        const SizedBox(height: 8), // Space before detail rows
      ],
    );
  }

  /// Builds a single detail row with an icon, label, and value.
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _lightTextColor),
          const SizedBox(width: 12),
          SizedBox(
            width: 90, // Consistent fixed width for labels
            child: Text(
              '$label:',
              style: const TextStyle(
                color: _lightTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a text content row for multi-line descriptions or notes.
  Widget _buildTextContentRow(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              color: _lightTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  _contentBoxColor, // Slightly different background for content box
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _borderColor.withOpacity(0.5),
              ), // Subtle border
            ),
            width: double.infinity,
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: _textColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper for Order Status Badge styling.
  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade100;
      case 'accepted':
        return Colors.green.shade100;
      case 'sent out for delivery':
        return Colors.blue.shade100;
      case 'delivered':
        return Colors.teal.shade100;
      case 'cancelled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  /// Helper for Order Status Badge text color.
  Color _getOrderStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade800;
      case 'accepted':
        return Colors.green.shade800;
      case 'sent out for delivery':
        return Colors.blue.shade800;
      case 'delivered':
        return Colors.teal.shade800;
      case 'cancelled':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  /// Builds the visual badge for the order status.
  Widget _buildOrderStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getOrderStatusColor(status),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getOrderStatusTextColor(status).withOpacity(0.3),
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _getOrderStatusTextColor(status),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
