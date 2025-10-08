import 'package:admin/Controller/order_report_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class IndividualOrderReportPage extends StatelessWidget {
  final Map<String, dynamic> order;

  IndividualOrderReportPage({super.key, required this.order});

  // Define a consistent and professional color palette, mirroring LeadDetailPage
  static const Color _primaryColor = Color(
    0xFFD13443,
  ); // A solid red for primary accents
  static const Color _accentColor = Color(
    0xFFD32F2F,
  ); // A strong red (same as primary here)
  static const Color _textColor = Color(
    0xFF212121,
  ); // Very dark grey for main text
  static const Color _lightTextColor = Color(
    0xFF616161,
  ); // Medium grey for labels and secondary text
  static const Color _cardColor =
      Colors.white; // Pure white for card backgrounds
  static const Color _backgroundColor = Color(
    0xFFF0F2F5,
  ); // Light off-white for scaffold background

  final controller = Get.put(OrderReportController());

  // Order status color methods (updated to match LeadDetailPage's style)
  Color _getOrderStatusColor(String status) {
    if (order['Cancel'] == true) {
      return _accentColor; // Strong red for cancelled
    }
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber.shade700; // Deeper amber for pending
      case 'accepted':
        return Colors.green.shade700; // Deeper green for accepted
      case 'sent out for delivery':
        return _primaryColor.withOpacity(0.9); // Primary color for delivery
      case 'delivered':
        return Colors.teal.shade700; // Deeper teal for delivered
      default:
        return Colors.grey.shade500;
    }
  }

  // Text color for status pills (always white for contrasting background colors)
  // ignore: unused_element
  Color _getOrderStatusTextColor(String status) {
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // Apply the light off-white background
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(
            fontWeight: FontWeight.w700, // Stronger weight for app bar title
            fontSize: 19,
            color: _textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: _cardColor, // White app bar background
        foregroundColor: _textColor, // Icons and text use the main text color
        elevation: 2, // Subtle shadow for app bar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20), // Modern back icon
          onPressed: () => Navigator.of(context).pop(),
          color: _textColor, // Icon color matches text
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: const Text(
                    'Are you sure you want to delete this order?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // 🔹 Show full-screen loader
                Get.dialog(
                  const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  ),
                  barrierDismissible: false,
                );

                try {
                  await controller.deleteOrder(
                    order['docId'],
                    context: context,
                  );
                } finally {
                  // 🔹 Hide loader
                  if (Get.isDialogOpen ?? false) Get.back();
                }
              }
            },
            label: Text(
              "Delete",
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Stretch card horizontally
          children: [
            // Main Order Detail Card
            Card(
              color: _cardColor, // Pure white card background
              elevation: 5, // A bit more elevation for prominence
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  15,
                ), // Softer, more modern rounded corners
              ),
              child: Padding(
                padding: const EdgeInsets.all(
                  24.0,
                ), // Generous padding inside the card
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Customer Name and Order Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            order['name'] ?? 'Unknown Customer',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          children: [
                            _buildStatusPill(order['order_status']),
                            buildEditedIndicator(
                              isEdited: order['isEdited'] ?? false,
                              dateChangeCount: order['dateChangeCount'] ?? 0,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16), // Space after name/status
                    // Customer ID & Order ID as Chips/Tags
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 8.0,
                      children: [
                        _buildInfoChip(
                          label: 'Customer ID',
                          value: order['customerId'] ?? 'N/A',
                          icon: Icons.person_outline,
                        ),
                        _buildInfoChip(
                          label: 'Order ID',
                          value: order['orderId'] ?? 'N/A',
                          icon: Icons.tag_outlined,
                        ),
                      ],
                    ),

                    const Divider(
                      height: 32,
                      thickness: 1,
                      color: Color(0xFFE0E0E0),
                    ), // Subtle divider
                    // Section for Contact & Order Details
                    _buildSectionTitle('Contact & Order Information'),
                    const SizedBox(height: 12),
                    _buildDetailRowWithIcon(
                      'Primary Phone',
                      order['phone1'] ?? 'N/A',
                      Icons.phone_outlined,
                    ),
                    if (order['address'] != null &&
                        order['address'].toString().isNotEmpty)
                      _buildDetailRowWithIcon(
                        'Address',
                        order['address'],
                        Icons.location_on_outlined,
                      ),
                    _buildDetailRowWithIcon(
                      'Place',
                      order['place'] ?? 'N/A',
                      Icons.place_outlined,
                    ),
                    _buildDetailRowWithIcon(
                      'Product ID',
                      order['productID'] ?? 'N/A',
                      Icons.shopping_bag_outlined,
                    ),
                    _buildDetailRowWithIcon(
                      'Quantity',
                      order['nos']?.toString() ?? 'N/A',
                      Icons.format_list_numbered_rtl_outlined,
                    ),
                    _buildDetailRowWithIcon(
                      'Salesman',
                      order['salesman'] ?? 'N/A',
                      Icons.person_outline,
                    ),
                    _buildDetailRowWithIcon(
                      'Maker',
                      order['maker'] ?? 'N/A',
                      Icons.build_outlined, // Changed icon for maker
                    ),

                    const Divider(
                      height: 32,
                      thickness: 1,
                      color: Color(0xFFE0E0E0),
                    ), // Subtle divider
                    // Section for Dates Information
                    _buildSectionTitle('Timeline'),
                    const SizedBox(height: 12),
                    _buildDetailRowWithIcon(
                      'Created On',
                      order['createdAt'] != null
                          ? DateFormat(
                              'MMM dd, yyyy, hh:mm a',
                            ).format(order['createdAt'])
                          : 'N/A',
                      Icons.event_note_outlined,
                    ),
                    if (order['deliveryDate'] != null)
                      _buildDetailRowWithIcon(
                        'Delivery Date',
                        DateFormat(
                          'MMM dd, yyyy, hh:mm a',
                        ).format(order['deliveryDate']),
                        Icons.local_shipping_outlined,
                      ),

                    // Remarks Section
                    if (order['remark'] != null &&
                        order['remark'].toString().isNotEmpty) ...[
                      const Divider(
                        height: 32,
                        thickness: 1,
                        color: Color(0xFFE0E0E0),
                      ), // Subtle divider
                      _buildSectionTitle('Remarks'),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              _backgroundColor, // Use light grey for remarks background
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          order['remark'],
                          style: const TextStyle(
                            fontSize: 15,
                            color: _textColor,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16), // Bottom padding
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets, mirrored from LeadDetailPage ---

  Widget _buildStatusPill(dynamic status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _getOrderStatusColor(status ?? ''),
        borderRadius: BorderRadius.circular(20), // More pronounced pill shape
      ),
      child: Text(
        (order['Cancel'] == true)
            ? 'CANCELLED'
            : (status ?? 'N/A').toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700, // Bolder text in pill
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor, // Use background color for chip fill
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
        ), // Light border for definition
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Keep chip content tight
        children: [
          Icon(icon, size: 16, color: _lightTextColor), // Smaller icon in chip
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _lightTextColor,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: _textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // No specific "Archived" tag for orders, but could be added if needed based on data.
  // Kept _buildArchivedTag from LeadDetailPage for reference if order also had archive status
  // Widget _buildArchivedTag() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //     decoration: BoxDecoration(
  //       color: Colors.red.shade50,
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: Colors.red.shade200),
  //     ),
  //     child: const Text(
  //       'ARCHIVED',
  //       style: TextStyle(
  //         color: Colors.red,
  //         fontWeight: FontWeight.bold,
  //         fontSize: 11,
  //         letterSpacing: 0.5,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _textColor, // Section titles are dark and bold
        ),
      ),
    );
  }

  Widget _buildDetailRowWithIcon(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
      ), // More vertical padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: _primaryColor.withOpacity(
              0.8,
            ), // Primary color for detail icons
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120, // Slightly wider fixed width for labels
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: _lightTextColor, // Lighter grey for labels
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: _textColor, // Main text color for values
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis, // Handle long values
              maxLines: 2, // Allow values to wrap
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEditedIndicator({
    required bool isEdited,
    required int dateChangeCount,
  }) {
    if (!isEdited) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 6), // small gap from status pill
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.orange.shade600,
        borderRadius: BorderRadius.circular(20), // pill shape
      ),
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: "Edited",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.top,
              child: Transform.translate(
                offset: const Offset(2, -6), // adjust position for superscript
                child: Text(
                  "$dateChangeCount",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
