// import 'package:admin/Controller/complaint_details_controller.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// class ComplaintDetailPage extends StatelessWidget {
//   final Map<String, dynamic> complaintData;

//   const ComplaintDetailPage({super.key, required this.complaintData});

//   // Define a consistent and professional color palette
//   static const Color _primaryColor = Color(
//     0xFFD13443,
//   ); // A solid red for primary accents
//   static const Color _accentColor = Color(
//     0xFFD32F2F,
//   ); // A strong red for warnings/high priority
//   static const Color _textColor = Color(
//     0xFF212121,
//   ); // Very dark grey for main text
//   static const Color _lightTextColor = Color(
//     0xFF616161,
//   ); // Medium grey for labels and secondary text
//   static const Color _cardColor =
//       Colors.white; // Pure white for card backgrounds
//   static const Color _backgroundColor = Color(
//     0xFFF0F2F5,
//   ); // Light off-white for scaffold background
//   static const Color _dividerColor = Color(
//     0xFFE0E0E0,
//   ); // Consistent divider color
//   static const Color _successColor = Colors.green; // For 'resolved' status
//   static const Color _warningColor = Colors.orange; // For 'in-progress' status
//   static const Color _infoColor = Colors.blue; // For 'pending' status

//   @override
//   Widget build(BuildContext context) {
//     // Initialize GetX controller
//     final controller = Get.put(ComplaintDetailController());
//     controller.initializeData(complaintData);

//     // Get screen width for responsive adjustments
//     final double screenWidth = MediaQuery.of(context).size.width;
//     final double horizontalPadding = screenWidth * 0.04; // 4% of screen width
//     final double cardPadding = screenWidth * 0.05; // 5% of screen width
//     final double titleFontSize = screenWidth * 0.055; // Adjust title font size
//     final double bodyFontSize = screenWidth * 0.038; // Adjust body font size
//     final double smallFontSize =
//         screenWidth * 0.03; // Adjust small text font size

//     return Scaffold(
//       backgroundColor: _backgroundColor,
//       appBar: AppBar(
//         title: Text(
//           'Complaint Details',
//           style: TextStyle(
//             fontWeight: FontWeight.w700,
//             fontSize:
//                 screenWidth * 0.045, // Smaller app bar title on smaller screens
//             color: _textColor,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: _cardColor,
//         foregroundColor: _textColor,
//         elevation: 2,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, size: 20),
//           onPressed: () => Navigator.of(context).pop(),
//           color: _textColor,
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(
//               Icons.refresh_outlined,
//               size: 20,
//               color: _textColor,
//             ),
//             onPressed: () => controller.update(),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.symmetric(
//           horizontal: horizontalPadding,
//           vertical: 16.0,
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Complaint Overview Card
//             _buildOverviewCard(
//               controller,
//               context,
//               cardPadding,
//               titleFontSize,
//               bodyFontSize,
//               smallFontSize,
//             ),
//             const SizedBox(height: 16),
//             // Response Input Section
//             _buildResponseSection(
//               controller,
//               context,
//               cardPadding,
//               titleFontSize,
//               bodyFontSize,
//               smallFontSize,
//             ),
//             const SizedBox(height: 16),
//             // Timeline of Responses/Updates
//             _buildTimelineSection(
//               controller,
//               context,
//               cardPadding,
//               titleFontSize,
//               bodyFontSize,
//               smallFontSize,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // --- Helper Widgets for Consistent Design ---

//   Widget _buildSectionTitle(String title, double fontSize, {Color? color}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Text(
//         title,
//         style: TextStyle(
//           fontSize: fontSize,
//           fontWeight: FontWeight.bold,
//           color: color ?? _textColor,
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRowWithIcon(
//     String label,
//     String value,
//     IconData icon,
//     double bodyFontSize,
//   ) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(
//             icon,
//             size: bodyFontSize * 1.3,
//             color: _lightTextColor,
//           ), // Icon size relative to body font
//           const SizedBox(width: 12),
//           SizedBox(
//             width: 90, // Slightly reduced fixed width for labels
//             child: Text(
//               '$label:',
//               style: TextStyle(
//                 fontWeight: FontWeight.w500,
//                 color: _lightTextColor,
//                 fontSize: bodyFontSize,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(
//                 fontSize: bodyFontSize,
//                 color: _textColor,
//                 fontWeight: FontWeight.w400,
//               ),
//               overflow: TextOverflow.ellipsis,
//               maxLines: 2,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Widget to display priority as a pill
//   Widget _buildPriorityPill(int priority, double smallFontSize) {
//     Color color;
//     String text;

//     switch (priority) {
//       case 1:
//         color = _successColor;
//         text = 'LOW';
//         break;
//       case 2:
//         color = _warningColor;
//         text = 'MEDIUM';
//         break;
//       case 3:
//         color = _accentColor;
//         text = 'HIGH';
//         break;
//       default:
//         color = Colors.grey.shade500;
//         text = 'UNKNOWN';
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 8,
//         vertical: 4,
//       ), // Reduced padding
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Text(
//         '$text PRIORITY',
//         style: TextStyle(
//           color: color,
//           fontWeight: FontWeight.w700,
//           fontSize: smallFontSize * 0.9, // Even smaller font for the pill
//         ),
//       ),
//     );
//   }

//   // Widget for complaint overview
//   Widget _buildOverviewCard(
//     ComplaintDetailController controller,
//     BuildContext context,
//     double cardPadding,
//     double titleFontSize,
//     double bodyFontSize,
//     double smallFontSize,
//   ) {
//     final createdAt = complaintData['timestamp'] != null
//         ? DateFormat(
//             'MMM dd, yyyy, hh:mm a',
//           ).format((complaintData['timestamp'] as Timestamp).toDate())
//         : 'N/A';
//     final priority = complaintData['priority'] ?? 1;

//     return Card(
//       color: _cardColor,
//       elevation: 5,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: EdgeInsets.all(cardPadding),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Text(
//                     complaintData['name'] ?? 'Unknown Customer',
//                     style: TextStyle(
//                       fontSize:
//                           titleFontSize *
//                           0.9, // Slightly smaller than main title
//                       fontWeight: FontWeight.bold,
//                       color: _textColor,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 _buildPriorityPill(priority, smallFontSize),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Complaint ID: ${complaintData['complaintId'] ?? 'N/A'}',
//               style: TextStyle(
//                 fontSize: smallFontSize,
//                 color: _lightTextColor,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const Divider(height: 32, thickness: 1, color: _dividerColor),
//             _buildDetailRowWithIcon(
//               'Category',
//               complaintData['category'] ?? 'N/A',
//               Icons.category_outlined,
//               bodyFontSize,
//             ),
//             _buildDetailRowWithIcon(
//               'Email',
//               complaintData['email'] ?? 'N/A',
//               Icons.email_outlined,
//               bodyFontSize,
//             ),
//             _buildDetailRowWithIcon(
//               'User Role',
//               complaintData['userRole'] ?? 'Unknown',
//               Icons.assignment_ind_outlined,
//               bodyFontSize,
//             ),
//             _buildDetailRowWithIcon(
//               'Created At',
//               createdAt,
//               Icons.event_note_outlined,
//               bodyFontSize,
//             ),
//             const SizedBox(height: 16),
//             _buildSectionTitle('Complaint Description', bodyFontSize * 1.1),
//             const SizedBox(height: 8),
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(
//                 bodyFontSize,
//               ), // Padding relative to body font size
//               decoration: BoxDecoration(
//                 color: _backgroundColor,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.grey.shade300),
//               ),
//               child: Text(
//                 complaintData['complaint'] ?? 'No description provided.',
//                 style: TextStyle(
//                   fontSize: bodyFontSize,
//                   color: _textColor,
//                   height: 1.5,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Widget for response input section
//   Widget _buildResponseSection(
//     ComplaintDetailController controller,
//     BuildContext context,
//     double cardPadding,
//     double titleFontSize,
//     double bodyFontSize,
//     double smallFontSize,
//   ) {
//     return Card(
//       color: _cardColor,
//       elevation: 5,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: EdgeInsets.all(cardPadding),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSectionTitle(
//               'Add Response',
//               titleFontSize * 0.9,
//               color: _primaryColor,
//             ),
//             const Divider(height: 24, thickness: 1, color: _dividerColor),
//             const SizedBox(height: 12),
//             Obx(
//               () => DropdownButtonFormField<String>(
//                 value: controller.selectedStatus.value,
//                 decoration: InputDecoration(
//                   labelText: 'Update Status',
//                   labelStyle: TextStyle(
//                     color: _lightTextColor,
//                     fontSize: bodyFontSize,
//                   ),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     borderSide: BorderSide(color: Colors.grey.shade300),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     borderSide: BorderSide(color: Colors.grey.shade300),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     borderSide: const BorderSide(
//                       color: _primaryColor,
//                       width: 2,
//                     ),
//                   ),
//                   contentPadding: EdgeInsets.symmetric(
//                     horizontal: bodyFontSize,
//                     vertical: bodyFontSize,
//                   ),
//                 ),
//                 items: ['pending', 'in-progress', 'resolved']
//                     .map(
//                       (status) => DropdownMenuItem(
//                         value: status,
//                         child: Text(
//                           status.toUpperCase(),
//                           style: TextStyle(
//                             color: _getStatusTextColor(status),
//                             fontWeight: FontWeight.w500,
//                             fontSize: bodyFontSize,
//                           ),
//                         ),
//                       ),
//                     )
//                     .toList(),
//                 onChanged: (value) => controller.selectedStatus.value = value!,
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: controller.responseController,
//               maxLines: 4,
//               decoration: InputDecoration(
//                 labelText: 'Response Message',
//                 labelStyle: TextStyle(
//                   color: _lightTextColor,
//                   fontSize: bodyFontSize,
//                 ),
//                 hintText: 'Enter your response to this complaint...',
//                 hintStyle: TextStyle(
//                   color: Colors.grey.shade400,
//                   fontSize: bodyFontSize,
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                   borderSide: BorderSide(color: Colors.grey.shade300),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                   borderSide: BorderSide(color: Colors.grey.shade300),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                   borderSide: const BorderSide(color: _primaryColor, width: 2),
//                 ),
//                 contentPadding: EdgeInsets.all(bodyFontSize),
//               ),
//               style: TextStyle(color: _textColor, fontSize: bodyFontSize),
//             ),
//             const SizedBox(height: 24),
//             Obx(
//               () => SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: controller.isLoading.value
//                       ? null
//                       : controller.submitResponse,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _primaryColor,
//                     foregroundColor: Colors.white,
//                     padding: EdgeInsets.symmetric(
//                       vertical: bodyFontSize + 4,
//                     ), // Adjusted padding
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     elevation: 3,
//                   ),
//                   child: controller.isLoading.value
//                       ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             color: Colors.white,
//                             strokeWidth: 2,
//                           ),
//                         )
//                       : Text(
//                           'Submit Response',
//                           style: TextStyle(
//                             fontSize: bodyFontSize,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Widget for previous responses/timeline section
//   Widget _buildTimelineSection(
//     ComplaintDetailController controller,
//     BuildContext context,
//     double cardPadding,
//     double titleFontSize,
//     double bodyFontSize,
//     double smallFontSize,
//   ) {
//     return Card(
//       color: _cardColor,
//       elevation: 5,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       child: Padding(
//         padding: EdgeInsets.all(cardPadding),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSectionTitle(
//               'Response History',
//               titleFontSize * 0.9,
//               color: Colors.blue.shade700,
//             ),
//             const Divider(height: 24, thickness: 1, color: _dividerColor),
//             const SizedBox(height: 12),
//             StreamBuilder<QuerySnapshot>(
//               stream: controller.firestore
//                   .collection('complaint_responses')
//                   .where('complaintId', isEqualTo: complaintData['complaintId'])
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(vertical: 20.0),
//                       child: CircularProgressIndicator(color: _primaryColor),
//                     ),
//                   );
//                 }
//                 if (snapshot.hasError) {
//                   return Center(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 20.0),
//                       child: Text(
//                         'Error: ${snapshot.error}',
//                         style: const TextStyle(color: _accentColor),
//                       ),
//                     ),
//                   );
//                 }
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return const Center(
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(vertical: 20.0),
//                       child: Text(
//                         'No responses yet.',
//                         style: TextStyle(
//                           color: _lightTextColor,
//                           fontStyle: FontStyle.italic,
//                         ),
//                       ),
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: snapshot.data!.docs.length,
//                   itemBuilder: (context, index) {
//                     final doc = snapshot.data!.docs[index];
//                     final data = doc.data() as Map<String, dynamic>;
//                     final timestamp = data['timestamp'] != null
//                         ? DateFormat(
//                             'MMM dd, yyyy, hh:mm a',
//                           ).format((data['timestamp'] as Timestamp).toDate())
//                         : 'N/A';
//                     final newStatus = data['newStatus']?.toString() ?? 'N/A';

//                     return _buildTimelineEntry(
//                       context,
//                       timestamp,
//                       data['response'] ?? 'No response text',
//                       newStatus,
//                       bodyFontSize,
//                       smallFontSize,
//                     );
//                   },
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Helper for status text color in dropdown
//   Color _getStatusTextColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return _infoColor;
//       case 'in-progress':
//         return _warningColor;
//       case 'resolved':
//         return _successColor;
//       default:
//         return _textColor;
//     }
//   }

//   // A new widget to represent a single timeline entry
//   Widget _buildTimelineEntry(
//     BuildContext context,
//     String timestamp,
//     String responseText,
//     String newStatus,
//     double bodyFontSize,
//     double smallFontSize,
//   ) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: EdgeInsets.all(
//         bodyFontSize,
//       ), // Padding relative to body font size
//       decoration: BoxDecoration(
//         color: _backgroundColor,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.history_toggle_off_outlined,
//                 size: bodyFontSize * 1.2,
//                 color: _primaryColor,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 timestamp,
//                 style: TextStyle(
//                   fontSize: smallFontSize,
//                   color: _lightTextColor,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const Spacer(),
//               if (newStatus != 'N/A')
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 6,
//                     vertical: 3,
//                   ), // Reduced padding
//                   decoration: BoxDecoration(
//                     color: _getStatusTextColor(newStatus).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(6),
//                     border: Border.all(
//                       color: _getStatusTextColor(newStatus).withOpacity(0.3),
//                     ),
//                   ),
//                   child: Text(
//                     newStatus.toUpperCase(),
//                     style: TextStyle(
//                       fontSize:
//                           smallFontSize *
//                           0.9, // Even smaller font for status chip
//                       fontWeight: FontWeight.w600,
//                       color: _getStatusTextColor(newStatus),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(
//             responseText,
//             style: TextStyle(
//               fontSize: bodyFontSize,
//               color: _textColor,
//               height: 1.4,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:admin/Controller/complaint_details_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ComplaintDetailPage extends StatelessWidget {
  final Map<String, dynamic> complaintData;

  const ComplaintDetailPage({super.key, required this.complaintData});

  // Minimal color palette
  static const Color _primary = Color(0xFF6366F1);
  static const Color _surface = Color(0xFFFAFAFA);
  static const Color _card = Colors.white;
  static const Color _text = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _error = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ComplaintDetailController());
    controller.initializeData(complaintData);

    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(context, controller),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildOverviewCard(controller),
            const SizedBox(height: 16),
            _buildResponseCard(controller),
            const SizedBox(height: 16),
            _buildTimelineCard(controller),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ComplaintDetailController controller,
  ) {
    return AppBar(
      title: const Text(
        'Complaint Details',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: _text,
        ),
      ),
      centerTitle: true,
      backgroundColor: _card,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 20, color: _text),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 20, color: _textSecondary),
          onPressed: () => controller.refreshData(),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(ComplaintDetailController controller) {
    final createdAt = complaintData['timestamp'] != null
        ? DateFormat(
            'MMM dd, yyyy • hh:mm a',
          ).format((complaintData['timestamp'] as Timestamp).toDate())
        : 'N/A';
    final priority = complaintData['priority'] ?? 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaintData['name'] ?? 'Unknown Customer',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${complaintData['complaintId'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildPriorityBadge(priority),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            Icons.category_outlined,
            'Category',
            complaintData['category'] ?? 'N/A',
          ),
          _buildInfoRow(
            Icons.email_outlined,
            'Email',
            complaintData['email'] ?? 'N/A',
          ),
          _buildInfoRow(
            Icons.person_outline,
            'Role',
            complaintData['userRole'] ?? 'Unknown',
          ),
          _buildInfoRow(Icons.schedule, 'Created', createdAt),
          const SizedBox(height: 20),
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _text,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: Text(
              complaintData['complaint'] ?? 'No description provided.',
              style: const TextStyle(fontSize: 14, color: _text, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: _text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(int priority) {
    Color color;
    String text;

    switch (priority) {
      case 1:
        color = _success;
        text = 'Low';
        break;
      case 2:
        color = _warning;
        text = 'Medium';
        break;
      case 3:
        color = _error;
        text = 'High';
        break;
      default:
        color = _textSecondary;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildResponseCard(ComplaintDetailController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Response',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _text,
            ),
          ),
          const SizedBox(height: 20),
          Obx(
            () => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: DropdownButtonFormField<String>(
                value: controller.selectedStatus.value,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: ['pending', 'in-progress', 'resolved']
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getStatusColor(status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _capitalizeFirst(status),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.selectedStatus.value = value;
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: TextField(
              controller: controller.responseController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Response Message',
                hintText: 'Enter your response...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.submitResponse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFD13443),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Response',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(ComplaintDetailController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Response History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _text,
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: controller.firestore
                .collection('complaint_responses')
                .where('complaintId', isEqualTo: complaintData['complaintId'])
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: _primary),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Error loading responses',
                      style: TextStyle(color: _error),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No responses yet',
                      style: TextStyle(
                        color: _textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildTimelineItem(data);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] != null
        ? DateFormat(
            'MMM dd • hh:mm a',
          ).format((data['timestamp'] as Timestamp).toDate())
        : 'N/A';
    final status = data['newStatus']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 16, color: _primary),
              const SizedBox(width: 8),
              Text(
                timestamp,
                style: const TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _capitalizeFirst(status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data['response'] ?? 'No response text',
            style: const TextStyle(fontSize: 14, color: _text, height: 1.4),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return _warning;
      case 'in-progress':
        return _primary;
      case 'resolved':
        return _success;
      default:
        return _textSecondary;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).replaceAll('-', ' ');
  }
}
