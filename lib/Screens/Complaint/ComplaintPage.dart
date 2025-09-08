import 'package:admin/Controller/complaint_controller.dart';
import 'package:admin/Screens/Complaint/complaintdetails.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ComplaintPage extends StatelessWidget {
  const ComplaintPage({super.key});

  // Define the primary accent color from the Signin page
  static const Color _primaryAccentColor = Color.fromARGB(255, 145, 28, 28);
  static const Color _darkTextColor = Color(0xFF030047); // From Signin page
  static Color _lightGreyFill =
      Colors.grey.shade50; // Light grey fill for filter section
  static Color _mediumGreyBorder = Colors.grey.shade300;
  static const double _borderRadius = 10.0; // Consistent border radius

  @override
  Widget build(BuildContext context) {
    final ComplaintController controller = Get.put(ComplaintController());

    return Scaffold(
      backgroundColor: Colors.white, // Consistent background
      appBar: AppBar(
        title: const Text(
          'Complaint Management',
          style: TextStyle(
            fontWeight: FontWeight.w600, // Slightly bolder for app bar title
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white, // Matching Signin button color
        foregroundColor: Colors.black,
        elevation: 0, // Flat app bar for modern look
        centerTitle: true, // Center title for a clean look
      ),
      body: Column(
        children: [
          _buildFilterSection(controller),
          Expanded(child: _buildComplaintsList(controller)),
        ],
      ),
    );
  }

  /// Builds the search bar and filter dropdowns section.
  Widget _buildFilterSection(ComplaintController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ), // Reduced padding
      decoration: BoxDecoration(
        color: _lightGreyFill, // Light grey fill for filter section
        border: Border(bottom: BorderSide(color: _mediumGreyBorder)),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) => controller.searchQuery.value = value,
            decoration: InputDecoration(
              hintText: 'Search complaints...',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ), // Consistent hint style
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey.shade600,
                size: 20,
              ), // Consistent icon style
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  _borderRadius,
                ), // Consistent border radius
                borderSide: BorderSide(color: _mediumGreyBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
                borderSide: BorderSide(color: _mediumGreyBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
                borderSide: const BorderSide(
                  color: Colors.white10, // Focused border color
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white, // White fill for text field
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, // Reduced padding
                vertical: 12, // Reduced padding
              ),
            ),
            style: const TextStyle(fontSize: 15), // Consistent input text style
          ),
          const SizedBox(height: 10), // Reduced spacing
          // Filter dropdowns
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: [
                  _buildFilterDropdown(
                    'Status',
                    controller.selectedStatus.value,
                    controller.statusOptions,
                    (value) => controller.selectedStatus.value = value!,
                  ),

                  const SizedBox(width: 8), // Reduced spacing
                  _buildFilterDropdown(
                    'Category',
                    controller.selectedCategory.value,
                    controller.categoryOptions,
                    (value) => controller.selectedCategory.value = value!,
                  ),
                  const SizedBox(width: 8), // Reduced spacing
                  _buildFilterDropdown(
                    'Role',
                    controller.selectedRole.value,
                    controller.roleOptions,
                    (value) => controller.selectedRole.value = value!,
                  ),
                  const SizedBox(width: 8), // Reduced spacing
                  // Clear filters button
                  ElevatedButton(
                    onPressed: () => controller.clearFilters(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _mediumGreyBorder, // Button background similar to disabled state
                      foregroundColor: Colors.grey.shade700,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          _borderRadius,
                        ), // Consistent border radius
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10, // Adjusted padding
                      ),
                      minimumSize: Size.zero, // Allows padding to control size
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ), // Adjusted font size
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget for building filter dropdowns.
  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 2,
      ), // Reduced padding
      decoration: BoxDecoration(
        border: Border.all(color: _mediumGreyBorder),
        borderRadius: BorderRadius.circular(
          _borderRadius,
        ), // Consistent border radius
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                _getDropdownLabel(label, option),
                style: const TextStyle(
                  fontSize: 13,
                  color: _darkTextColor,
                ), // Consistent text style
              ),
            );
          }).toList(),
          onChanged: onChanged,
          isDense: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.grey.shade600,
          ), // Consistent icon color
        ),
      ),
    );
  }

  /// Helper to format dropdown labels.
  String _getDropdownLabel(String filterType, String option) {
    if (option == 'All') {
      return '$filterType: All';
    }

    if (filterType == 'Priority') {
      switch (option) {
        case '1':
          return 'Low (1)';
        case '2':
          return 'Medium (2)';
        case '3':
          return 'High (3)';
        default:
          return option;
      }
    }
    return option;
  }

  /// Builds the main complaints list with loading, error, and empty states.
  Widget _buildComplaintsList(ComplaintController controller) {
    return Obx(
      () => StreamBuilder<QuerySnapshot>(
        stream: controller.getFilteredComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  _primaryAccentColor,
                ), // Primary color spinner
                strokeWidth: 2,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ), // Adjusted font size
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No complaints found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ), // Adjusted font size
                  ),
                ],
              ),
            );
          }

          // Enrich complaints with user data (FutureBuilder)
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: controller.enrichComplaintsWithUserData(
              snapshot.data!.docs,
            ),
            builder: (context, enrichedSnapshot) {
              if (enrichedSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _primaryAccentColor,
                    ), // Primary color spinner
                    strokeWidth: 2,
                  ),
                );
              }

              if (enrichedSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading data: ${enrichedSnapshot.error}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ), // Adjusted font size
                  ),
                );
              }

              final complaints = enrichedSnapshot.data ?? [];
              final filteredComplaints = controller.applyTextSearch(complaints);

              if (filteredComplaints.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No complaints match your filters',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ), // Adjusted font size
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12), // Reduced list padding
                itemCount: filteredComplaints.length,
                itemBuilder: (context, index) {
                  return _buildComplaintCard(filteredComplaints[index]);
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Builds an individual complaint card.
  Widget _buildComplaintCard(Map<String, dynamic> data) {
    final createdAt = data['timestamp'] != null
        ? DateFormat(
            'dd MMM yyyy, hh:mm a',
          ).format((data['timestamp'] as Timestamp).toDate())
        : 'N/A';

    final priority = data['priority'] ?? 1;
    final status = data['status'] ?? 'pending';

    return Card(
      color: Colors.white, // Consistent card color
      margin: const EdgeInsets.only(bottom: 10), // Reduced margin
      elevation: 1, // Softer shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ), // Consistent border radius
      child: InkWell(
        borderRadius: BorderRadius.circular(_borderRadius),
        onTap: () => _navigateToComplaintDetail(data),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data['category'] ?? 'No category',
                      style: const TextStyle(
                        fontSize: 15, // Adjusted font size
                        fontWeight: FontWeight.bold,
                        color: _darkTextColor, // Consistent text color
                      ),
                    ),
                  ),
                  _buildPriorityChip(priority),
                  const SizedBox(width: 6), // Reduced spacing
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 10), // Reduced spacing
              // User info
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 15,
                    color: Colors.grey.shade600,
                  ), // Adjusted icon size
                  const SizedBox(width: 4),
                  Text(
                    data['name'] ?? 'N/A',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 14, // Adjusted font size
                    ),
                  ),
                  const SizedBox(width: 12), // Reduced spacing
                  Icon(
                    Icons.badge,
                    size: 15,
                    color: Colors.grey.shade600,
                  ), // Adjusted icon size
                  const SizedBox(width: 4),
                  Text(
                    data['userRole'] ?? 'Unknown',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 14, // Adjusted font size
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6), // Reduced spacing
              // Complaint preview
              Text(
                data['complaint'] ?? 'N/A',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 14,
                ), // Adjusted font size
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10), // Reduced spacing
              // Footer
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 13, // Adjusted icon size
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    createdAt,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ), // Adjusted font size
                  ),
                  const Spacer(),
                  Text(
                    'Tap to view details',
                    style: TextStyle(
                      color: _primaryAccentColor, // Consistent accent color
                      fontSize: 11, // Adjusted font size
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a colored chip for displaying priority.
  Widget _buildPriorityChip(int priority) {
    Color color;
    String text;

    switch (priority) {
      case 1:
        color = Colors.green.shade600; // Slightly darker green
        text = 'Low';
        break;
      case 2:
        color = Colors.orange.shade600; // Slightly darker orange
        text = 'Medium';
        break;
      case 3:
        color = Colors.red.shade600; // Slightly darker red
        text = 'High';
        break;
      default:
        color = Colors.grey.shade600;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ), // Reduced vertical padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          10,
        ), // Consistent smaller border radius
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11, // Adjusted font size
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Builds a colored chip for displaying status.
  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange.shade600; // Slightly darker orange
        break;
      case 'in-progress':
        color = Colors.blue.shade600; // Slightly darker blue
        break;
      case 'resolved':
        color = Colors.green.shade600; // Slightly darker green
        break;
      default:
        color = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ), // Reduced vertical padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          10,
        ), // Consistent smaller border radius
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11, // Adjusted font size
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Navigates to the complaint detail page.
  void _navigateToComplaintDetail(Map<String, dynamic> complaintData) {
    Get.to(() => ComplaintDetailPage(complaintData: complaintData));
  }
}
