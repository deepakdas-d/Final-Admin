import 'package:admin/Controller/order_report_controller.dart';
import 'package:admin/Screens/Orders/individual_order_report.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class OrderReport extends StatelessWidget {
  final OrderReportController controller = Get.put(OrderReportController());

  OrderReport({Key? key}) : super(key: key);

  void init() {
    controller.onInit();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate visible tiles based on screen height and estimated card height
    final double screenHeight = MediaQuery.of(context).size.height;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    final textScaleFactor = mediaQuery.textScaler.scale(1.0);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;

    // Calculate responsive dimensions

    final double basePadding = screenWidth * 0.04;

    // final textScaleFactor = mediaQuery.textScaler.scale(1.0);
    final double appBarHeight = kToolbarHeight;
    final double filterSectionHeight =
        screenHeight * 0.25; // Approx filter height
    final double summaryHeight = screenHeight * 0.06; // Approx summary height
    final double cardHeight = screenHeight * 0.12; // Approx height of each card
    final int visibleTiles =
        ((screenHeight - appBarHeight - filterSectionHeight - summaryHeight) /
                cardHeight)
            .ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Reports',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[900],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export order',
            onPressed: () => _showExportOptions(context),
          ),

          IconButton(
            onPressed: controller.clearFilters,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Filters',
          ),
          // IconButton(
          //   icon: const Icon(Icons.refresh_rounded),
          //   onPressed: () => controller.fetchOrders(isRefresh: true),
          //   tooltip: 'Refresh',
          // ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
            height: filterSectionHeight * 0.90,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) => controller.searchQuery.value = value,
                  decoration: InputDecoration(
                    hintText: 'Search Orders...',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),

                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 17,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                // Filter Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.08,
                    child: Row(
                      children: [
                        // Status Filter
                        Obx(
                          () => _buildFilterDrop(
                            context: context,
                            label: 'Status',
                            value: controller.statusFilter.value,
                            items: [
                              'All',
                              'pending',
                              'accepted',
                              'sent out for delivery',
                              'delivered',
                            ],
                            onChanged: controller.setStatusFilter,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.03,
                        ),
                        // Place Filter
                        Obx(
                          () => _buildFilterDropdown(
                            context: context,
                            label: 'Place',
                            value: controller.placeFilter.value.isEmpty
                                ? null
                                : controller.placeFilter.value,
                            items: ['All', ...controller.availablePlaces],
                            onChanged: controller.setPlaceFilter,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.03,
                        ),
                        // Salesperson Filter
                        // Obx(
                        //   () => _buildFilterDropdown(
                        //     context: context,
                        //     label: 'Salesperson',
                        //     value: controller.salespersonFilter.value.isEmpty
                        //         ? null
                        //         : controller.salespersonFilter.value,
                        //     items: ['All', ...controller.availableSalespeople],
                        //     onChanged: controller.setSalespersonFilter,
                        //   ),
                        // ),
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
                              value: controller.salespersonFilter.value.isEmpty
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
                                      style: TextStyle(fontSize: 10),
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
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.03,
                        ),
                        // Date Range Filter
                        _buildDateRangeFilter(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Summary Section
          Obx(
            () => Container(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.04,
                vertical: MediaQuery.of(context).size.height * 0.01,
              ),
              height: summaryHeight,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Total Orders: ${controller.totalMatchingOrders}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          // Orders List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.paginatedOrders.isEmpty) {
                return _buildShimmerList(context, visibleTiles);
              }

              if (controller.paginatedOrders.isEmpty &&
                  !controller.isLoading.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: MediaQuery.of(context).size.width * 0.15,
                        color: Colors.grey,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      Text(
                        'No orders found',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.045,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: controller.scrollController,
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.04,
                ),
                itemCount:
                    controller.paginatedOrders.length +
                    (controller.isLoadingMore.value ? visibleTiles : 0),
                itemBuilder: (context, index) {
                  if (index >= controller.paginatedOrders.length) {
                    return _buildShimmerCard(context);
                  }
                  final order = controller.paginatedOrders[index];
                  return _buildOrderCard(order, context);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final borderRadius = BorderRadius.circular(
      MediaQuery.of(context).size.width * 0.02,
    );

    // Remove 'All' from items and use empty string for "no filter"
    final dropdownItems = ['', ...items.where((item) => item != 'All')];

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.48,
      height: MediaQuery.of(context).size.height * 0.065,
      child: DropdownButtonFormField<String>(
        value: value?.isEmpty ?? true ? null : value,
        decoration: InputDecoration(
          hintText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.03,
            vertical: MediaQuery.of(context).size.height * 0.01,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: Colors.blue, width: 1.2),
          ),
        ),
        items: dropdownItems.map((String item) {
          return DropdownMenuItem<String>(
            value: item.isEmpty ? '' : item,
            child: Text(
              item.isEmpty ? 'All $label' : item,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.035,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildFilterDrop({
    required BuildContext context,
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final borderRadius = BorderRadius.circular(
      MediaQuery.of(context).size.width * 0.02,
    );

    // Remove 'All' from items and use empty string for "no filter"
    final dropdownItems = ['', ...items.where((item) => item != 'All')];

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.55,
      height: MediaQuery.of(context).size.height * 0.065,
      child: DropdownButtonFormField<String>(
        value: value?.isEmpty ?? true ? null : value,
        decoration: InputDecoration(
          hintText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.03,
            vertical: MediaQuery.of(context).size.height * 0.01,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: Colors.blue, width: 1.2),
          ),
        ),
        items: dropdownItems.map((String item) {
          return DropdownMenuItem<String>(
            value: item.isEmpty ? '' : item,
            child: Text(
              item.isEmpty ? 'All $label' : item,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.035,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateRangeFilter(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.45,
      height: MediaQuery.of(context).size.height * 0.065,
      child: InkWell(
        onTap: () async {
          final DateTimeRange? picked = await showDateRangePicker(
            context: Get.context!,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            initialDateRange:
                controller.startDate.value != null &&
                    controller.endDate.value != null
                ? DateTimeRange(
                    start: controller.startDate.value!,
                    end: controller.endDate.value!,
                  )
                : null,
          );
          controller.setDateRange(picked);
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.03,
            vertical: MediaQuery.of(context).size.height * 0.02,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(
              MediaQuery.of(context).size.width * 0.02,
            ),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Icon(
                Icons.date_range,
                size: MediaQuery.of(context).size.width * 0.05,
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
              Expanded(
                child: Obx(
                  () => Text(
                    controller.startDate.value != null &&
                            controller.endDate.value != null
                        ? '${DateFormat('MMM dd').format(controller.startDate.value!)} - ${DateFormat('MMM dd').format(controller.endDate.value!)}'
                        : 'Date Range',
                    style: TextStyle(
                      color: controller.startDate.value != null
                          ? Colors.black
                          : Colors.grey.shade600,
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.01,
      ),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          MediaQuery.of(context).size.width * 0.02,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IndividualOrderReportPage(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(
          MediaQuery.of(context).size.width * 0.02,
        ),
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
          child: Row(
            children: [
              // Order Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['name'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.005,
                    ),
                    Text(
                      'ID: ${order['orderId'] ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: MediaQuery.of(context).size.width * 0.028,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.005,
                    ),
                    Text(
                      order['place'] ?? 'N/A',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: MediaQuery.of(context).size.width * 0.03,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status and Arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.015,
                      vertical: MediaQuery.of(context).size.height * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: controller.getOrderStatusColor(
                        order['order_status'] ?? '',
                      ),
                      borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.width * 0.02,
                      ),
                    ),
                    child: Text(
                      order['order_status'] ?? 'N/A',
                      style: TextStyle(
                        color: controller.getOrderStatusTextColor(
                          order['order_status'] ?? '',
                        ),
                        fontSize: MediaQuery.of(context).size.width * 0.025,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: MediaQuery.of(context).size.width * 0.03,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.01,
        ),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            MediaQuery.of(context).size.width * 0.02,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: MediaQuery.of(context).size.height * 0.02,
                      color: Colors.white,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.005,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.2,
                      height: MediaQuery.of(context).size.height * 0.015,
                      color: Colors.white,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.005,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      height: MediaQuery.of(context).size.height * 0.015,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.15,
                    height: MediaQuery.of(context).size.height * 0.02,
                    color: Colors.white,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.03,
                    height: MediaQuery.of(context).size.width * 0.03,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList(BuildContext context, int visibleTiles) {
    return ListView.builder(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      itemCount: visibleTiles,
      itemBuilder: (context, index) => _buildShimmerCard(context),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export Order Report',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Export with Current Filters
              const Text(
                'Export with Current Filters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF'),
                      onPressed: controller.isExporting.value
                          ? null
                          : () {
                              Navigator.pop(context);
                              controller.downloadAllOrdersDataAsPDF(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.grid_on),
                      label: const Text('Excel'),
                      onPressed: controller.isExporting.value
                          ? null
                          : () {
                              Navigator.pop(context);
                              controller.downloadAllOrdersDataAsExcel(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Export by Salesperson
              const Text(
                'Export by Salesperson',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Obx(
                () => DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Salesperson',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  value: null,
                  items: controller.availableSalespeople.map((salesperson) {
                    return DropdownMenuItem(
                      value: salesperson,
                      child: Text(
                        salesperson,
                        style: const TextStyle(fontSize: 14),
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
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Export $value\'s Orders',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.picture_as_pdf),
                                        label: const Text('PDF'),
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
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.grid_on),
                                        label: const Text('Excel'),
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
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
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
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 20),
              // Share Options
              const Text(
                'Share Filtered Orders',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share PDF'),
                      onPressed: controller.isExporting.value
                          ? null
                          : () {
                              Navigator.pop(context);
                              controller.shareAllOrdersDataAsPDF(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share Excel'),
                      onPressed: controller.isExporting.value
                          ? null
                          : () {
                              Navigator.pop(context);
                              controller.shareAllOrdersDataAsExcel(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
