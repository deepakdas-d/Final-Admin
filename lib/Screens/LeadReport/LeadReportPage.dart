import 'package:admin/Screens/LeadReport/individual_lead_report.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:admin/Controller/lead_report_controller.dart';

class LeadReport extends StatelessWidget {
  LeadReport({super.key});
  final controller = Get.put(LeadReportController());

  @override
  Widget build(BuildContext context) {
    // MediaQuery data
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final textScaleFactor = mediaQuery.textScaler.scale(1.0);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;

    // Calculate responsive dimensions
    const double appBarHeight = kToolbarHeight;
    final double filterSectionHeight = screenHeight * (isPortrait ? 0.25 : 0.2);
    final double summaryHeight = screenHeight * (isPortrait ? 0.06 : 0.08);
    final double cardHeight = screenHeight * (isPortrait ? 0.18 : 0.15);
    final double basePadding = screenWidth * 0.04;
    final double baseFontSize = screenWidth * 0.04 * textScaleFactor;
    final int visibleTiles =
        ((screenHeight - appBarHeight - filterSectionHeight - summaryHeight) /
                cardHeight)
            .ceil();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Lead Reports',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18 * textScaleFactor,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[900],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.download, size: 24 * textScaleFactor),
            tooltip: 'Export Leads',
            onPressed: () => _showExportOptions(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchLeads(isRefresh: true),
        child: Column(
          children: [
            // Filters Section
            Container(
              padding: EdgeInsets.all(basePadding),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 50 * (isPortrait ? 1.0 : 0.9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.grey.shade50,
                    ),
                    child: TextField(
                      controller: controller.searchController,
                      decoration: InputDecoration(
                        hintText: 'Name, Lead ID, Phone, Place, or Salesman',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14 * textScaleFactor,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: basePadding,
                          vertical: 12 * textScaleFactor,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.grey.shade600,
                          size: 20 * textScaleFactor,
                        ),
                        suffixIcon: Obx(
                          () => controller.searchQuery.value.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    size: 20 * textScaleFactor,
                                  ),
                                  onPressed: () {
                                    controller.searchController.clear();
                                    controller.onSearchChanged('');
                                  },
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                      onChanged: controller.onSearchChanged,
                      style: TextStyle(fontSize: 14 * textScaleFactor),
                    ),
                  ),
                  SizedBox(height: basePadding),
                  // Filters Row
                  SizedBox(
                    height: 35 * (isPortrait ? 1.5 : 0.9),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Salesperson Filter
                          Container(
                            width: screenWidth * (isPortrait ? 0.55 : 0.3),
                            margin: EdgeInsets.only(right: basePadding),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                              color: Colors.white,
                            ),
                            child: Obx(
                              () => DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: InputDecoration(
                                  hintText: 'All Salesperson',
                                  labelStyle: TextStyle(
                                    fontSize: 10 * textScaleFactor,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: basePadding,
                                    vertical: 8 * textScaleFactor,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_rounded,
                                    size: 15 * textScaleFactor,
                                  ),
                                ),
                                value:
                                    controller.salespersonFilter.value.isEmpty
                                    ? null
                                    : controller.salespersonFilter.value,
                                items: [
                                  DropdownMenuItem(
                                    value: '',
                                    child: Text(
                                      'All Salesmen',
                                      style: TextStyle(
                                        fontSize: 10 * textScaleFactor,
                                      ),
                                    ),
                                  ),
                                  ...controller.availableSalespeople.map((
                                    salesperson,
                                  ) {
                                    return DropdownMenuItem(
                                      value: salesperson,
                                      child: Text(
                                        salesperson,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10 * textScaleFactor,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                                onChanged: controller.setSalespersonFilter,
                                style: TextStyle(
                                  fontSize: 13 * textScaleFactor,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          // Status Filter
                          Container(
                            width: screenWidth * (isPortrait ? 0.52 : 0.25),
                            margin: EdgeInsets.only(right: basePadding),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                              color: Colors.white,
                            ),
                            child: Obx(
                              () => DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: InputDecoration(
                                  hintText: 'All Status',
                                  labelStyle: TextStyle(
                                    fontSize: 10 * textScaleFactor,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: basePadding,
                                    vertical: 8 * textScaleFactor,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.filter_list_rounded,
                                    size: 15 * textScaleFactor,
                                  ),
                                ),
                                value: controller.statusFilter.value.isEmpty
                                    ? null
                                    : controller.statusFilter.value,
                                items: ['All Status', 'WARM', 'COOL'].map((
                                  status,
                                ) {
                                  return DropdownMenuItem(
                                    value: status == 'All Status' ? '' : status,
                                    child: Row(
                                      children: [
                                        if (status != 'All Status')
                                          Container(
                                            width: 12 * textScaleFactor,
                                            height: 12 * textScaleFactor,
                                            margin: EdgeInsets.only(
                                              right: basePadding / 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: controller.getStatusColor(
                                                status,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: controller
                                                    .getStatusTextColor(status),
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 10 * textScaleFactor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: controller.setStatusFilter,
                                style: TextStyle(
                                  fontSize: 13 * textScaleFactor,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),

                          Container(
                            width: screenWidth * (isPortrait ? 0.43 : 0.2),
                            margin: EdgeInsets.only(right: basePadding),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                              color: Colors.white,
                            ),
                            child: Obx(
                              () => DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: InputDecoration(
                                  hintText: 'All Place',
                                  labelStyle: TextStyle(
                                    fontSize: 10 * textScaleFactor,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: basePadding,
                                    vertical: 8 * textScaleFactor,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.location_on_rounded,
                                    size: 15 * textScaleFactor,
                                  ),
                                ),

                                // ✅ Safely set the current value
                                value:
                                    controller.availablePlaces.contains(
                                      controller.placeFilter.value,
                                    )
                                    ? controller.placeFilter.value
                                    : null,

                                // ✅ Build dropdown items
                                items: [
                                  const DropdownMenuItem(
                                    value: '',
                                    child: Text('All Places'),
                                  ),
                                  ...controller.availablePlaces.map((place) {
                                    return DropdownMenuItem(
                                      value: place,
                                      child: Text(
                                        place,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10 * textScaleFactor,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],

                                // ✅ On change
                                onChanged: controller.setPlaceFilter,

                                style: TextStyle(
                                  fontSize: 13 * textScaleFactor,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),

                          // Date Range Button
                          SizedBox(
                            width: screenWidth * (isPortrait ? 0.38 : 0.2),
                            height: 58 * (isPortrait ? 1.0 : 0.9),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: Colors.indigo.shade700,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                controller.setDateRange(picked);
                              },
                              icon: Icon(
                                Icons.date_range_rounded,
                                size: 18 * textScaleFactor,
                              ),
                              label: Obx(
                                () => Text(
                                  controller.startDate.value != null
                                      ? 'Date Selected'
                                      : 'Select Date',
                                  style: TextStyle(
                                    fontSize: 10 * textScaleFactor,
                                  ),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade50,
                                foregroundColor: Colors.indigo.shade700,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  horizontal: basePadding,
                                  vertical: 8 * textScaleFactor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: basePadding),
                          // Clear Filters Button
                          Obx(
                            () =>
                                (controller.statusFilter.value.isNotEmpty ||
                                    controller.placeFilter.value.isNotEmpty ||
                                    controller
                                        .salespersonFilter
                                        .value
                                        .isNotEmpty ||
                                    controller.startDate.value != null ||
                                    controller.searchQuery.value.isNotEmpty)
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.shade200,
                                      ),
                                    ),
                                    child: IconButton(
                                      onPressed: controller.clearFilters,
                                      icon: Icon(
                                        Icons.clear_all_rounded,
                                        color: Colors.red.shade600,
                                        size: 20 * textScaleFactor,
                                      ),
                                      tooltip: 'Clear Filters',
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Stats Row
            Obx(
              () => Container(
                height: summaryHeight * (isPortrait ? 1.9 : 1.5),
                padding: EdgeInsets.symmetric(horizontal: basePadding),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'Total',
                      controller.totalLeads.toString(),
                      Colors.blue,
                      context,
                      baseFontSize,
                    ),
                    _buildStatCard(
                      'Warm',
                      controller.warmLeads.toString(),
                      Colors.orange,
                      context,
                      baseFontSize,
                    ),
                    _buildStatCard(
                      'Cool',
                      controller.coolLeads.toString(),
                      Colors.indigo,
                      context,
                      baseFontSize,
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Obx(() {
                // 🔄 Show shimmer effect when loading (initial or filter)
                if (controller.isLoading.value) {
                  return _buildShimmerList(context, visibleTiles, basePadding);
                }

                // ❌ No data found
                if (controller.paginatedLeads.isEmpty &&
                    !controller.isLoadingMore.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: screenWidth * 0.15,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'No leads found',
                          style: TextStyle(
                            fontSize: baseFontSize * 1.1,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // ✅ Show lead list with pagination
                return ListView.builder(
                  controller: controller.scrollController,
                  padding: EdgeInsets.all(basePadding),
                  itemCount:
                      controller.paginatedLeads.length +
                      (controller.isLoadingMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < controller.paginatedLeads.length) {
                      final lead = controller.paginatedLeads[index];
                      return _buildLeadCard(
                        context,
                        lead,
                        controller,
                        basePadding,
                        baseFontSize,
                        textScaleFactor,
                      );
                    } else {
                      // 🔽 Bottom pagination loader
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    BuildContext context,
    double baseFontSize,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    // ignore: unused_local_variable
    final textScaleFactor = mediaQuery.textScaler.scale(1.0);

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: baseFontSize * 1.2,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: baseFontSize * 0.8,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadCard(
    BuildContext context,
    Map<String, dynamic> lead,
    LeadReportController controller,
    double basePadding,
    double baseFontSize,
    double textScaleFactor,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Get.to(() => LeadDetailPage(lead: lead));
        },
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        child: Padding(
          padding: EdgeInsets.all(basePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Profile Avatar
                  CircleAvatar(
                    radius: screenWidth * 0.05,
                    backgroundColor: Color(0xFFD13443).withOpacity(0.8),
                    child: Text(
                      lead['name'].toString().isNotEmpty
                          ? lead['name'].toString()[0].toUpperCase()
                          : 'L',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 251, 252, 255),
                        fontWeight: FontWeight.bold,
                        fontSize: baseFontSize,
                      ),
                    ),
                  ),
                  SizedBox(width: basePadding),
                  // Name and Lead ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: baseFontSize * 1.1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${lead['leadId']}',
                          style: TextStyle(
                            fontSize: baseFontSize * 0.8,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: basePadding / 2,
                      vertical: screenHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: controller.getStatusColor(lead['status']),
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      border: Border.all(
                        color: controller.getStatusTextColor(lead['status']),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      lead['status'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: baseFontSize * 0.7,
                        fontWeight: FontWeight.bold,
                        color: controller.getStatusTextColor(lead['status']),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.015),
              // Details Grid
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.phone_rounded,
                      'Phone',
                      lead['phone1'] ?? 'N/A',
                      context,
                      baseFontSize,
                      basePadding,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.person_rounded,
                      'Salesman',
                      lead['salesman'] ?? 'N/A',
                      context,
                      baseFontSize,
                      basePadding,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.01),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.location_on_rounded,
                      'Place',
                      lead['place'] ?? 'N/A',
                      context,
                      baseFontSize,
                      basePadding,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.calendar_today_rounded,
                      'Created',
                      DateFormat('MMM dd, yyyy').format(lead['createdAt']),
                      context,
                      baseFontSize,
                      basePadding,
                    ),
                  ),
                ],
              ),
              // Follow-up indicator
              if (lead['followUpDate'] != null) ...[
                SizedBox(height: screenHeight * 0.01),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: basePadding / 2,
                    vertical: screenHeight * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: baseFontSize * 0.9,
                        color: Colors.amber.shade700,
                      ),
                      SizedBox(width: basePadding / 2),
                      Text(
                        'Follow-up: ${DateFormat('MMM dd').format(lead['followUpDate'])}',
                        style: TextStyle(
                          fontSize: baseFontSize * 0.7,
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    IconData icon,
    String label,
    String value,
    BuildContext context,
    double baseFontSize,
    double basePadding,
  ) {
    final mediaQuery = MediaQuery.of(context);
    // ignore: unused_local_variable
    final screenWidth = mediaQuery.size.width;

    return Row(
      children: [
        Icon(icon, size: baseFontSize, color: Colors.grey.shade600),
        SizedBox(width: basePadding / 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: baseFontSize * 0.7,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: baseFontSize * 0.8,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard(
    BuildContext context,
    double basePadding,
    double baseFontSize,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    // ignore: unused_local_variable
    final textScaleFactor = mediaQuery.textScaler.scale(1.0);

    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: EdgeInsets.only(bottom: screenHeight * 0.015),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(basePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  CircleAvatar(
                    radius: screenWidth * 0.05,
                    backgroundColor: Colors.grey[300],
                  ),
                  SizedBox(width: basePadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: screenWidth * 0.4,
                          height: baseFontSize,
                          color: Colors.white,
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Container(
                          width: screenWidth * 0.3,
                          height: baseFontSize * 0.8,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: screenWidth * 0.15,
                    height: baseFontSize,
                    color: Colors.white,
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.015),
              // Details Grid
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: baseFontSize,
                          height: baseFontSize,
                          color: Colors.white,
                        ),
                        SizedBox(width: basePadding / 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: screenWidth * 0.2,
                                height: baseFontSize * 0.8,
                                color: Colors.white,
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Container(
                                width: screenWidth * 0.25,
                                height: baseFontSize * 0.8,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: baseFontSize,
                          height: baseFontSize,
                          color: Colors.white,
                        ),
                        SizedBox(width: basePadding / 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: screenWidth * 0.2,
                                height: baseFontSize * 0.8,
                                color: Colors.white,
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Container(
                                width: screenWidth * 0.25,
                                height: baseFontSize * 0.8,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.01),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: baseFontSize,
                          height: baseFontSize,
                          color: Colors.white,
                        ),
                        SizedBox(width: basePadding / 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: screenWidth * 0.2,
                                height: baseFontSize * 0.8,
                                color: Colors.white,
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Container(
                                width: screenWidth * 0.25,
                                height: baseFontSize * 0.8,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: baseFontSize,
                          height: baseFontSize,
                          color: Colors.white,
                        ),
                        SizedBox(width: basePadding / 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: screenWidth * 0.2,
                                height: baseFontSize * 0.8,
                                color: Colors.white,
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Container(
                                width: screenWidth * 0.25,
                                height: baseFontSize * 0.8,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildShimmerList(
    BuildContext context,
    int visibleTiles,
    double basePadding,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(basePadding),
      itemCount: visibleTiles,
      itemBuilder: (context, index) =>
          _buildShimmerCard(context, basePadding, basePadding),
    );
  }

  void _showExportOptions(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final textScaleFactor = mediaQuery.textScaler.scale(1.0);
    final basePadding = screenWidth * 0.04;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.all(basePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Lead Report',
                style: TextStyle(
                  fontSize: 18 * textScaleFactor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: basePadding),
              // Export with Current Filters
              Text(
                'Export with Current Filters',
                style: TextStyle(
                  fontSize: 16 * textScaleFactor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: basePadding / 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(
                        Icons.picture_as_pdf,
                        size: 18 * textScaleFactor,
                      ),
                      label: Text(
                        'PDF',
                        style: TextStyle(fontSize: 14 * textScaleFactor),
                      ),
                      onPressed: controller.isExporting.value
                          ? null
                          : () {
                              Navigator.pop(context);
                              controller.downloadAllLeadsDataAsPDF(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: basePadding),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: basePadding / 2),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.grid_on, size: 18 * textScaleFactor),
                      label: Text(
                        'Excel',
                        style: TextStyle(fontSize: 14 * textScaleFactor),
                      ),
                      onPressed: controller.isExporting.value
                          ? null
                          : () {
                              Navigator.pop(context);
                              controller.downloadAllLeadsDataAsExcel(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: basePadding),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: basePadding),
              // Export by Salesperson
              Text(
                'Export by Salesperson',
                style: TextStyle(
                  fontSize: 16 * textScaleFactor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: basePadding / 2),
              Obx(
                () => DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Salesperson',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: basePadding,
                      vertical: 8 * textScaleFactor,
                    ),
                  ),
                  value: null,
                  items: controller.availableSalespeople.map((salesperson) {
                    return DropdownMenuItem(
                      value: salesperson,
                      child: Text(
                        salesperson,
                        style: TextStyle(fontSize: 14 * textScaleFactor),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) {
                          return Padding(
                            padding: EdgeInsets.all(basePadding),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Export $value\'s Leads',
                                  style: TextStyle(
                                    fontSize: 18 * textScaleFactor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: basePadding),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: Icon(
                                          Icons.picture_as_pdf,
                                          size: 18 * textScaleFactor,
                                        ),
                                        label: Text(
                                          'PDF',
                                          style: TextStyle(
                                            fontSize: 14 * textScaleFactor,
                                          ),
                                        ),
                                        onPressed: controller.isExporting.value
                                            ? null
                                            : () {
                                                Navigator.pop(context);
                                                controller
                                                    .downloadSingleSalesmanAsPDF(
                                                      context,
                                                      value,
                                                    );
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical: basePadding,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: basePadding / 2),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: Icon(
                                          Icons.grid_on,
                                          size: 18 * textScaleFactor,
                                        ),
                                        label: Text(
                                          'Excel',
                                          style: TextStyle(
                                            fontSize: 14 * textScaleFactor,
                                          ),
                                        ),
                                        onPressed: controller.isExporting.value
                                            ? null
                                            : () {
                                                Navigator.pop(context);
                                                controller
                                                    .downloadSingleSalesmanAsExcel(
                                                      context,
                                                      value,
                                                    );
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical: basePadding,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                  },
                  style: TextStyle(
                    fontSize: 14 * textScaleFactor,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: basePadding / 2),
              // Share Options
              Text(
                'Share Filtered Leads',
                style: TextStyle(
                  fontSize: 16 * textScaleFactor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: basePadding / 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.share, size: 18 * textScaleFactor),
                      label: Text(
                        'Share PDF',
                        style: TextStyle(fontSize: 14 * textScaleFactor),
                      ),
                      onPressed: controller.isExporting.value
                          ? null
                          : () {
                              Navigator.pop(context);
                              controller.shareAllLeadsDataAsPDF(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: basePadding),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: basePadding / 2),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.share, size: 18 * textScaleFactor),
                      label: Text(
                        'Share Excel',
                        style: TextStyle(fontSize: 14 * textScaleFactor),
                      ),
                      onPressed: controller.isExporting.value
                          ? null
                          : () {
                              Navigator.pop(context);
                              controller.shareAllLeadsDataAsExcel(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: basePadding),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
