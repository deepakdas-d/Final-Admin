import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:developer';

// Assume these exist or need to be implemented based on your project

class PostSaleFollowupController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<Map<String, dynamic>> allOrders = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMoreData = true.obs;
  final RxBool isDataLoaded = false.obs;
  final RxList<String> availablePlaces = <String>[].obs;
  final RxList<String> availableSalespeople = <String>[].obs;

  DocumentSnapshot? _lastDocument;
  final int itemsPerPage = 10;

  // Filter variables
  final RxString searchQuery = ''.obs;
  final RxString placeFilter = ''.obs;
  final RxString salespersonFilter = ''.obs;
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  RxInt totalMatchingOrders = 0.obs;

  // Pagination for filtered data (for display)
  final RxList<Map<String, dynamic>> filteredOrders =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> paginatedOrders =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingMore = false.obs;
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
    // Add listeners for filter changes to re-filter orders
    everAll([searchQuery, placeFilter, salespersonFilter, startDate, endDate], (
      _,
    ) {
      filterOrders();
    });

    scrollController.addListener(_scrollListener);
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels ==
            scrollController.position.maxScrollExtent &&
        !isLoading.value &&
        hasMoreData.value &&
        !isLoadingMore.value) {
      log('Reached end of list, loading more...');
      fetchOrders();
    }
  }

  Future<String> getSalesmanName(String? uid) async {
    if (uid == null || uid.isEmpty) return 'N/A';
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final name = doc.data()?['name'];
        return name ?? 'Unknown';
      } else {
        return 'Not Found';
      }
    } catch (e) {
      log('Error fetching user for $uid: $e');
      return 'Error';
    }
  }

  Future<String> getmakerName(String? uid) async {
    if (uid == null || uid.isEmpty) return 'N/A';
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final name = doc.data()?['name'];
        return name ?? 'Unknown';
      } else {
        return 'Not Found';
      }
    } catch (e) {
      log('Error fetching user for $uid: $e');
      return 'Error';
    }
  }

  /// Fetches a paginated list of delivered orders from Firestore.
  ///
  /// Set `isRefresh` to `true` to clear existing data and start from the beginning.
  Future<void> fetchOrders({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        _lastDocument = null;
        allOrders.clear();
        hasMoreData.value = true;
        isDataLoaded.value = false; // Reset data loaded flag
      }

      if (!hasMoreData.value || isLoading.value || isLoadingMore.value) {
        return; // Prevent multiple simultaneous fetches
      }

      if (allOrders.isEmpty) {
        isLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }

      Query<Map<String, dynamic>> query = _firestore
          .collection('Orders')
          .orderBy('createdAt', descending: true)
          .where('order_status', isEqualTo: 'delivered')
          .limit(itemsPerPage);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot<Map<String, dynamic>> orderSnapshot = await query.get();

      if (orderSnapshot.docs.isEmpty) {
        hasMoreData.value = false;
        isLoading.value = false;
        isLoadingMore.value = false;
        if (allOrders.isEmpty) {
          isDataLoaded.value = true; // No data, but finished loading
        }
        return;
      }

      List<Map<String, dynamic>> tempOrders = [];
      Set<String> placesSet = <String>{};
      Set<String> salespeopleSet = <String>{};

      for (var doc in orderSnapshot.docs) {
        final data = doc.data();
        final String? salesmanID = data['salesmanID'];
        final String salesmanName = await getSalesmanName(salesmanID);
        final String? makerID = data['makerId'];
        final String maker = await getmakerName(makerID);

        tempOrders.add({
          'address': data['address'] ?? '',
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'deliveryDate': (data['deliveryDate'] as Timestamp?)?.toDate(),
          'followUpDate': (data['followUpDate'] as Timestamp?)?.toDate(),
          'makerId': data['makerId'] ?? '',
          'name': data['name'] ?? '',
          'nos': data['nos'] ?? 0,
          'orderId': data['orderId'] ?? '',
          'order_status': data['order_status'] ?? '',
          'phone1': data['phone1'] ?? '',
          'phone2': data['phone2'] ?? '',
          'place': data['place'] ?? '',
          'productID': data['productID'] ?? '',
          'remark': data['remark'] ?? '',
          'salesman': salesmanName,
          'maker': maker,
          'followUpNotes': data['followUpNotes'] ?? '',
        });

        final place = data['place']?.toString().trim();
        if (place != null && place.isNotEmpty) {
          placesSet.add(place);
        }
        if (salesmanName.isNotEmpty && salesmanName != 'N/A') {
          salespeopleSet.add(salesmanName);
        }
      }

      _lastDocument = orderSnapshot.docs.last;
      allOrders.addAll(tempOrders);

      // Only update available filters if refreshing or if they are empty
      if (isRefresh || availablePlaces.isEmpty) {
        availablePlaces.value = placesSet.toList()..sort();
        availableSalespeople.value = salespeopleSet.toList()..sort();
      }

      filterOrders();
      isDataLoaded.value = true;
    } catch (e) {
      log('Error fetching orders: $e');
      Get.snackbar(
        'Error',
        'Failed to fetch orders: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> fetchTotalFilteredOrderCount() async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('Orders')
          .where('order_status', isEqualTo: 'delivered'); // ✅ Only delivered

      if (placeFilter.value.isNotEmpty) {
        query = query.where('place', isEqualTo: placeFilter.value);
      }

      // ✅ Convert selected salesperson name to ID
      if (salespersonFilter.value.isNotEmpty) {
        final userSnap = await _firestore
            .collection('users')
            .where('name', isEqualTo: salespersonFilter.value)
            .limit(1)
            .get();

        if (userSnap.docs.isNotEmpty) {
          final salesmanId = userSnap.docs.first.id;
          query = query.where('salesmanID', isEqualTo: salesmanId);
        } else {
          // No matching salesman
          totalMatchingOrders.value = 0;
          return;
        }
      }

      if (startDate.value != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate.value!),
        );
      }

      if (endDate.value != null) {
        query = query.where(
          'createdAt',
          isLessThan: Timestamp.fromDate(
            endDate.value!.add(const Duration(days: 1)),
          ),
        );
      }

      final countSnapshot = await query.count().get();
      totalMatchingOrders.value = countSnapshot.count ?? 0;
    } catch (e) {
      print('Error fetching total order count: $e');
      totalMatchingOrders.value = 0;
    }
  }

  void filterOrders() {
    List<Map<String, dynamic>> tempFilteredOrders = allOrders.where((order) {
      final String name = order['name']?.toString().toLowerCase() ?? '';
      final String orderId = order['orderId']?.toString().toLowerCase() ?? '';
      final String place = order['place']?.toString().toLowerCase() ?? '';
      final String salesman = order['salesman']?.toString().toLowerCase() ?? '';

      final String query = searchQuery.value.toLowerCase();
      final bool matchesSearch =
          name.contains(query) || orderId.contains(query);

      final bool matchesPlace =
          placeFilter.value.isEmpty ||
          placeFilter.value == 'All' ||
          place == placeFilter.value.toLowerCase();

      final bool matchesSalesperson =
          salespersonFilter.value.isEmpty ||
          salespersonFilter.value == 'All' ||
          salesman == salespersonFilter.value.toLowerCase();

      final DateTime? orderDeliveryDate = order['deliveryDate'] as DateTime?;
      final bool matchesDateRange =
          startDate.value == null ||
          (orderDeliveryDate != null &&
              orderDeliveryDate.isAfter(startDate.value!) &&
              orderDeliveryDate.isBefore(
                endDate.value!.add(const Duration(days: 1)),
              )); // Include end day

      return matchesSearch &&
          matchesPlace &&
          matchesSalesperson &&
          matchesDateRange;
    }).toList();

    filteredOrders.value = tempFilteredOrders;
    paginatedOrders.value = tempFilteredOrders;
    fetchTotalFilteredOrderCount();
  }

  void setPlaceFilter(String? value) {
    placeFilter.value = value ?? '';
  }

  void setSalespersonFilter(String? value) {
    salespersonFilter.value = value ?? '';
  }

  void setDateRange(DateTimeRange? range) {
    startDate.value = range?.start;
    endDate.value = range?.end;
  }

  void clearFilters() {
    searchQuery.value = '';
    placeFilter.value = '';
    salespersonFilter.value = '';
    startDate.value = null;
    endDate.value = null;
    // No need to call filterOrders() here, as the Rx variables will trigger it.
  }

  Color getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green.shade100;
      case 'pending':
        return Colors.orange.shade100;
      case 'cancelled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color getOrderStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green.shade800;
      case 'pending':
        return Colors.orange.shade800;
      case 'cancelled':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  Future<List<Map<String, dynamic>>> _getFilteredOrdersDataForReport() async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('Orders')
          .where('order_status', isEqualTo: 'delivered')
          .orderBy('createdAt', descending: true);

      // Apply filters from controller's Rx variables
      if (placeFilter.value.isNotEmpty) {
        query = query.where('place', isEqualTo: placeFilter.value);
      }
      if (salespersonFilter.value.isNotEmpty) {
        // Fetch user ID for the selected salesman name
        final userSnapshot = await _firestore
            .collection('users')
            .where('name', isEqualTo: salespersonFilter.value)
            .get();
        if (userSnapshot.docs.isNotEmpty) {
          final userId = userSnapshot.docs.first.id;
          query = query.where('salesmanID', isEqualTo: userId);
        } else {
          return []; // No matching salesman found
        }
      }
      if (startDate.value != null && endDate.value != null) {
        query = query.where(
          'deliveryDate', // Use deliveryDate for PostSaleFollowup
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate.value!),
        );
        query = query.where(
          'deliveryDate',
          isLessThanOrEqualTo: Timestamp.fromDate(
            endDate.value!.add(const Duration(days: 1)),
          ),
        );
      }

      final QuerySnapshot<Map<String, dynamic>> orderSnapshot = await query
          .get();

      List<Map<String, dynamic>> fullOrdersData = [];
      for (var doc in orderSnapshot.docs) {
        final data = doc.data();
        final String? salesmanID = data['salesmanID'];
        final String salesmanName = await getSalesmanName(salesmanID);
        final String? makerID = data['makerId'];
        final String maker = await getmakerName(makerID);

        // Apply client-side search query filtering
        final String clientSearchQuery = searchQuery.value.toLowerCase();
        final String name = data['name']?.toString().toLowerCase() ?? '';
        final String orderId = data['orderId']?.toString().toLowerCase() ?? '';
        final String phone1 = data['phone1']?.toString().toLowerCase() ?? '';
        final String phone2 = data['phone2']?.toString().toLowerCase() ?? '';
        final String place = data['place']?.toString().toLowerCase() ?? '';
        final String orderStatus =
            data['order_status']?.toString().toLowerCase() ?? '';

        if (clientSearchQuery.isNotEmpty &&
            !(name.contains(clientSearchQuery) ||
                orderId.contains(clientSearchQuery) ||
                phone1.contains(clientSearchQuery) ||
                phone2.contains(clientSearchQuery) ||
                place.contains(clientSearchQuery) ||
                salesmanName.toLowerCase().contains(clientSearchQuery) ||
                orderStatus.contains(clientSearchQuery))) {
          continue;
        }

        fullOrdersData.add({
          'address': data['address'] ?? '',
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'deliveryDate': (data['deliveryDate'] as Timestamp?)?.toDate(),
          'followUpDate': (data['followUpDate'] as Timestamp?)?.toDate(),
          'makerId': data['makerId'] ?? '',
          'name': data['name'] ?? '',
          'nos': data['nos'] ?? 0,
          'orderId': data['orderId'] ?? '',
          'order_status': data['order_status'] ?? '',
          'phone1': data['phone1'] ?? '',
          'phone2': data['phone2'] ?? '',
          'place': data['place'] ?? '',
          'productID': data['productID'] ?? '',
          'remark': data['remark'] ?? '',
          'salesman': salesmanName,
          'maker': maker,
          'followUpNotes': data['followUpNotes'] ?? '',
        });
      }
      return fullOrdersData;
    } catch (e) {
      log('Error fetching orders for report: $e');
      Get.snackbar(
        'Error',
        'Failed to retrieve orders for report: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return [];
    }
  }

  Future<bool> checkStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 30) {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;
    } else {
      final status = await Permission.storage.request();
      if (status.isGranted) return true;
    }

    Get.snackbar(
      'Permission Required',
      'Storage permission required. Please enable it in settings.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      mainButton: TextButton(
        onPressed: openAppSettings,
        child: const Text(
          'Open Settings',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );

    return false;
  }

  Future<File> _generateOrdersExcelFile(
    List<Map<String, dynamic>> ordersData,
  ) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Delivered Orders'];

    // Add filter description
    final filterDescription = [
      if (salespersonFilter.value.isNotEmpty)
        'Salesperson: ${salespersonFilter.value}',
      if (placeFilter.value.isNotEmpty) 'Place: ${placeFilter.value}',
      if (startDate.value != null && endDate.value != null)
        'Date Range: ${DateFormat('dd-MMM-yyyy').format(startDate.value!)} to ${DateFormat('dd-MMM-yyyy').format(endDate.value!)}',
      if (searchQuery.value.isNotEmpty) 'Search: ${searchQuery.value}',
    ].join(' | ');

    if (filterDescription.isNotEmpty) {
      var filterCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      );
      filterCell.value = TextCellValue('Filters: $filterDescription');
      filterCell.cellStyle = CellStyle(fontSize: 12, italic: true);
      sheet.setRowHeight(0, 20);
    }

    // Define headers
    final headers = [
      'Order ID',
      'Customer Name',
      'Phone 1',
      'Phone 2',
      'Address',
      'Place',
      'NOS',
      'Product ID',
      'Salesman',
      'Maker',
      'Order Status',
      'Created At',
      'Delivery Date',
      'Follow Up Date',
      'Remark',
      'Follow Up Notes',
    ];

    // Set column widths
    final columnWidths = [
      15.0,
      25.0,
      15.0,
      15.0,
      30.0,
      20.0,
      10.0,
      15.0,
      15.0,
      15.0,
      15.0,
      20.0,
      20.0,
      20.0,
      25.0,
      30.0,
    ];

    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, columnWidths[i]);
      var cell = sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: i,
          rowIndex: filterDescription.isNotEmpty ? 1 : 0,
        ),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Populate data rows
    final dateFormat = DateFormat('dd-MMM-yyyy HH:mm');
    for (int rowIndex = 0; rowIndex < ordersData.length; rowIndex++) {
      final order = ordersData[rowIndex];
      final rowData = [
        order['orderId']?.toString() ?? 'N/A',
        order['name']?.toString() ?? 'N/A',
        order['phone1']?.toString() ?? 'N/A',
        order['phone2']?.toString() ?? 'N/A',
        order['address']?.toString() ?? 'N/A',
        order['place']?.toString() ?? 'N/A',
        order['nos']?.toString() ?? 'N/A',
        order['productID']?.toString() ?? 'N/A',
        order['salesman']?.toString() ?? 'N/A',
        order['maker']?.toString() ?? 'N/A',
        order['order_status']?.toString() ?? 'N/A',
        (order['createdAt'] as DateTime?) != null
            ? dateFormat.format(order['createdAt'])
            : 'N/A',
        (order['deliveryDate'] as DateTime?) != null
            ? dateFormat.format(order['deliveryDate'])
            : 'N/A',
        (order['followUpDate'] as DateTime?) != null
            ? dateFormat.format(order['followUpDate'])
            : 'N/A',
        order['remark']?.toString() ?? 'N/A',
        order['followUpNotes']?.toString() ?? 'N/A',
      ];

      for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: colIndex,
            rowIndex: rowIndex + (filterDescription.isNotEmpty ? 2 : 1),
          ),
        );
        cell.value = TextCellValue(rowData[colIndex]);

        // Apply color coding to the 'Order Status' column
        if (colIndex == 10) {
          final status = order['order_status']?.toString().toLowerCase();
          cell.cellStyle = CellStyle(
            backgroundColorHex: status == 'delivered'
                ? ExcelColor.fromHexString('#C8E6C9')
                : ExcelColor.fromHexString('#FFFFFF'),
          );
        }
      }
    }

    // Add summary row
    final summaryRow =
        ordersData.length + (filterDescription.isNotEmpty ? 3 : 2);
    var summaryCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow),
    );
    summaryCell.value = TextCellValue('Total Orders: ${ordersData.length}');
    summaryCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 12,
      backgroundColorHex: ExcelColor.fromHexString('#E0E0E0'),
    );

    // Add timestamp
    var timestampCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 1),
    );
    timestampCell.value = TextCellValue(
      'Generated on: ${dateFormat.format(DateTime.now().toLocal())}',
    );
    timestampCell.cellStyle = CellStyle(italic: true, fontSize: 10);

    // Save to temporary directory for sharing consistency
    final outputDir = await getTemporaryDirectory();
    final file = File(
      '${outputDir.path}/delivered_orders_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    } else {
      throw Exception('Failed to encode Excel file.');
    }

    return file;
  }

  /// Downloads all "delivered" order data as a PDF document (based on current filters).
  // Future<void> downloadAllOrdersDataAsPDF(BuildContext context) async {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => const AlertDialog(
  //       content: Row(
  //         children: [
  //           CircularProgressIndicator(),
  //           SizedBox(width: 16),
  //           Text('Generating PDF...'),
  //         ],
  //       ),
  //     ),
  //   );

  //   try {
  //     final ordersData =
  //         await _getFilteredOrdersDataForReport(); // Use filtered data

  //     if (ordersData.isEmpty) {
  //       if (context.mounted) Navigator.of(context).pop();
  //       if (context.mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('No orders found to download in PDF.'),
  //             backgroundColor: Colors.orange,
  //           ),
  //         );
  //       }
  //       return;
  //     }

  //     // Create PDF document
  //     final pdf = pw.Document();

  //     pdf.addPage(
  //       pw.MultiPage(
  //         pageFormat: PdfPageFormat.a4.portrait.copyWith(
  //           marginLeft: PdfPageFormat.mm / 4,
  //           marginRight: PdfPageFormat.mm / 4,
  //           marginTop: PdfPageFormat.mm / 4,
  //           marginBottom: PdfPageFormat.mm / 4,
  //         ), // Adjusted margins for more content space
  //         build: (pw.Context context) {
  //           return [
  //             pw.Header(
  //               level: 0,
  //               child: pw.Text(
  //                 'All Delivered Orders Data',
  //                 style: pw.TextStyle(
  //                   fontSize: 20, // Slightly smaller font for header
  //                   fontWeight: pw.FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //             pw.SizedBox(height: 10), // Reduced spacing
  //             // Use a Table for better PDF presentation of tabular data
  //             pw.Table.fromTextArray(
  //               headers: [
  //                 'Order ID',
  //                 'Customer Name',
  //                 'Place',
  //                 'NOS',
  //                 'Salesman',
  //                 'Maker',
  //                 'Status',
  //                 'Created At',
  //               ],
  //               data: ordersData.map((order) {
  //                 return [
  //                   order['orderId'] ?? 'N/A',
  //                   order['name'] ?? 'N/A',
  //                   order['place'] ?? 'N/A',
  //                   order['nos']?.toString() ?? 'N/A',
  //                   order['salesman'] ?? 'N/A',
  //                   order['maker'] ?? 'N/A',
  //                   order['order_status'] ?? 'N/A',
  //                   (order['createdAt'] as DateTime?)
  //                           ?.toLocal()
  //                           .toString()
  //                           .split('.')[0] ??
  //                       'N/A',
  //                 ];
  //               }).toList(),
  //               border: pw.TableBorder.all(),
  //               headerStyle: pw.TextStyle(
  //                 fontWeight: pw.FontWeight.bold,
  //                 fontSize: 8,
  //               ), // Smaller header font
  //               headerDecoration: const pw.BoxDecoration(
  //                 color: PdfColors.grey300,
  //               ),
  //               cellAlignment: pw.Alignment.centerLeft,
  //               cellPadding: const pw.EdgeInsets.all(3), // Smaller cell padding
  //               cellStyle: const pw.TextStyle(fontSize: 7), // Smaller cell font
  //             ),
  //             pw.SizedBox(height: 15),
  //             pw.Text(
  //               'Total Orders: ${ordersData.length}',
  //               style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
  //             ),
  //             pw.Text(
  //               'Generated on: ${DateTime.now().toLocal().toString().split('.')[0]}',
  //               style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
  //             ),
  //           ];
  //         },
  //       ),
  //     );

  //     final outputDir = await getApplicationDocumentsDirectory();
  //     final fileName =
  //         'all_orders_data_${DateTime.now().millisecondsSinceEpoch}.pdf';
  //     final file = File('${outputDir.path}/$fileName');
  //     await file.writeAsBytes(await pdf.save());

  //     if (context.mounted) Navigator.of(context).pop();

  //     if (context.mounted) {
  //       showDialog(
  //         context: context,
  //         builder: (context) => AlertDialog(
  //           title: const Text('PDF Generated'),
  //           content: Text(
  //             'PDF "$fileName" has been saved to app documents directory. Would you like to open it?',
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.of(context).pop(),
  //               child: const Text('Cancel'),
  //             ),
  //             TextButton(
  //               onPressed: () async {
  //                 if (context.mounted) Navigator.of(context).pop();
  //                 final result = await OpenFile.open(file.path);
  //                 if (result.type != ResultType.done) {
  //                   if (context.mounted) {
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       SnackBar(
  //                         content: Text(
  //                           'Could not open PDF: ${result.message}',
  //                         ),
  //                         backgroundColor: Colors.red,
  //                       ),
  //                     );
  //                   }
  //                 }
  //               },
  //               child: const Text('Open'),
  //             ),
  //           ],
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (context.mounted) Navigator.of(context).pop();
  //     log('Error downloading orders PDF: $e');
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error downloading PDF: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }
  Future<void> downloadAllOrdersDataAsPDF(BuildContext context) async {
    if (isLoading.value) return;

    bool hasPermission = await checkStoragePermission();
    if (!hasPermission) return;

    isLoading.value = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating PDF...'),
          ],
        ),
      ),
    );

    try {
      final ordersData = await _getFilteredOrdersDataForReport();

      if (ordersData.isEmpty) {
        if (context.mounted) Navigator.of(context).pop();
        Get.snackbar(
          'No Data',
          'No orders found to download in PDF based on current filters.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final pdf = pw.Document();
      final dateFormat = DateFormat('dd-MMM-yyyy HH:mm');

      // Create filter description
      final filterDescription = [
        if (salespersonFilter.value.isNotEmpty)
          'Salesperson: ${salespersonFilter.value}',
        if (placeFilter.value.isNotEmpty) 'Place: ${placeFilter.value}',
        if (startDate.value != null && endDate.value != null)
          'Date Range: ${dateFormat.format(startDate.value!)} to ${dateFormat.format(endDate.value!)}',
        if (searchQuery.value.isNotEmpty) 'Search: ${searchQuery.value}',
      ].join(' | ');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape.copyWith(
            marginLeft: 30,
            marginRight: 30,
            marginTop: 20,
            marginBottom: 20,
          ),
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Text(
                  'Delivered Orders Report',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if (filterDescription.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text(
                  'Filters: $filterDescription',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  'Order ID',
                  'Customer Name',
                  'Phone 1',
                  'Phone 2',
                  'Place',
                  'Salesman',
                  'Maker',
                  'Order Status',
                  'Created At',
                  'Delivery Date',
                  'Follow Up Date',
                  'NOS',
                ],
                data: ordersData.map((order) {
                  return [
                    order['orderId']?.toString() ?? 'N/A',
                    order['name']?.toString() ?? 'N/A',
                    order['phone1']?.toString() ?? 'N/A',
                    order['phone2']?.toString() ?? 'N/A',
                    order['place']?.toString() ?? 'N/A',
                    order['salesman']?.toString() ?? 'N/A',
                    order['maker']?.toString() ?? 'N/A',
                    order['order_status']?.toString() ?? 'N/A',
                    (order['createdAt'] as DateTime?) != null
                        ? dateFormat.format(order['createdAt'])
                        : 'N/A',
                    (order['deliveryDate'] as DateTime?) != null
                        ? dateFormat.format(order['deliveryDate'])
                        : 'N/A',
                    (order['followUpDate'] as DateTime?) != null
                        ? dateFormat.format(order['followUpDate'])
                        : 'N/A',
                    order['nos']?.toString() ?? 'N/A',
                  ];
                }).toList(),
                border: pw.TableBorder.all(width: 1),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(5),
                cellStyle: pw.TextStyle(fontSize: 9),
                cellHeight: 30,
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5), // Order ID
                  1: const pw.FlexColumnWidth(2.5), // Customer Name
                  2: const pw.FlexColumnWidth(1.5), // Phone 1
                  3: const pw.FlexColumnWidth(1.5), // Phone 2
                  4: const pw.FlexColumnWidth(2), // Place
                  5: const pw.FlexColumnWidth(2), // Salesman
                  6: const pw.FlexColumnWidth(2), // Maker
                  7: const pw.FlexColumnWidth(1.5), // Order Status
                  8: const pw.FlexColumnWidth(2), // Created At
                  9: const pw.FlexColumnWidth(2), // Delivery Date
                  10: const pw.FlexColumnWidth(2), // Follow Up Date
                  11: const pw.FlexColumnWidth(1), // NOS
                },
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Total Orders: ${ordersData.length}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                'Generated on: ${dateFormat.format(DateTime.now().toLocal())}',
                style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic,
                  fontSize: 10,
                ),
              ),
            ];
          },
        ),
      );

      final outputDir = await getApplicationDocumentsDirectory();
      final fileName =
          'delivered_orders_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) Navigator.of(context).pop();
      Get.snackbar(
        'PDF Generated',
        'PDF report saved to ${file.path.split('/').last}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        mainButton: TextButton(
          onPressed: () => OpenFile.open(file.path),
          child: const Text('Open File', style: TextStyle(color: Colors.white)),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      log('Error downloading orders PDF: $e');
      Get.snackbar(
        'Error',
        'Failed to download PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> downloadAllOrdersDataAsExcel(BuildContext context) async {
    if (isLoading.value) return;

    bool hasPermission = await checkStoragePermission();
    if (!hasPermission) return;

    isLoading.value = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating Excel...'),
          ],
        ),
      ),
    );

    try {
      final ordersData = await _getFilteredOrdersDataForReport();

      if (ordersData.isEmpty) {
        if (context.mounted) Navigator.of(context).pop();
        Get.snackbar(
          'No Data',
          'No orders found to download in Excel based on current filters.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final file = await _generateOrdersExcelFile(ordersData);
      if (context.mounted) Navigator.of(context).pop();

      Get.snackbar(
        'Excel Generated',
        'Excel report saved to ${file.path.split('/').last}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        mainButton: TextButton(
          onPressed: () => OpenFile.open(file.path),
          child: const Text('Open File', style: TextStyle(color: Colors.white)),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      log('Error downloading orders Excel: $e');
      Get.snackbar(
        'Error',
        'Failed to download Excel: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Downloads data for a single salesman as a PDF (respects other filters).
  Future<void> downloadSingleSalesmanAsPDF(
    BuildContext context,
    String salesmanName,
  ) async {
    if (isLoading.value) return;
    salespersonFilter.value = salesmanName;
    await downloadAllOrdersDataAsPDF(context);
    salespersonFilter.value = '';
  }

  /// Downloads data for a single salesman as an Excel file (respects other filters).
  Future<void> downloadSingleSalesmanAsExcel(
    BuildContext context,
    String salesmanName,
  ) async {
    if (isLoading.value) return;
    salespersonFilter.value = salesmanName;
    await downloadAllOrdersDataAsExcel(context);
    salespersonFilter.value = '';
  }

  /// Shares all "delivered" order data as a PDF file (based on current filters).
  Future<void> shareAllOrdersDataAsPDF(BuildContext context) async {
    if (isLoading.value) return;

    bool hasPermission = await checkStoragePermission();
    if (!hasPermission) return;

    isLoading.value = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text(
              'Preparing PDF for sharing...',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );

    try {
      final ordersData = await _getFilteredOrdersDataForReport();

      if (ordersData.isEmpty) {
        if (context.mounted) Navigator.of(context).pop();
        Get.snackbar(
          'No Data',
          'No orders found to share in PDF based on current filters.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final pdf = pw.Document();
      final dateFormat = DateFormat('dd-MMM-yyyy HH:mm');

      // Create filter description
      final filterDescription = [
        if (salespersonFilter.value.isNotEmpty)
          'Salesperson: ${salespersonFilter.value}',
        if (placeFilter.value.isNotEmpty) 'Place: ${placeFilter.value}',
        if (startDate.value != null && endDate.value != null)
          'Date Range: ${dateFormat.format(startDate.value!)} to ${dateFormat.format(endDate.value!)}',
        if (searchQuery.value.isNotEmpty) 'Search: ${searchQuery.value}',
      ].join(' | ');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape.copyWith(
            marginLeft: 30,
            marginRight: 30,
            marginTop: 20,
            marginBottom: 20,
          ),
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Text(
                  'Delivered Orders Report',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if (filterDescription.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text(
                  'Filters: $filterDescription',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  'Order ID',
                  'Customer Name',
                  'Phone 1',
                  'Phone 2',
                  'Place',
                  'Salesman',
                  'Maker',
                  'Order Status',
                  'Created At',
                  'Delivery Date',
                  'Follow Up Date',
                  'NOS',
                ],
                data: ordersData.map((order) {
                  return [
                    order['orderId']?.toString() ?? 'N/A',
                    order['name']?.toString() ?? 'N/A',
                    order['phone1']?.toString() ?? 'N/A',
                    order['phone2']?.toString() ?? 'N/A',
                    order['place']?.toString() ?? 'N/A',
                    order['salesman']?.toString() ?? 'N/A',
                    order['maker']?.toString() ?? 'N/A',
                    order['order_status']?.toString() ?? 'N/A',
                    (order['createdAt'] as DateTime?) != null
                        ? dateFormat.format(order['createdAt'])
                        : 'N/A',
                    (order['deliveryDate'] as DateTime?) != null
                        ? dateFormat.format(order['deliveryDate'])
                        : 'N/A',
                    (order['followUpDate'] as DateTime?) != null
                        ? dateFormat.format(order['followUpDate'])
                        : 'N/A',
                    order['nos']?.toString() ?? 'N/A',
                  ];
                }).toList(),
                border: pw.TableBorder.all(width: 1),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(5),
                cellStyle: pw.TextStyle(fontSize: 9),
                cellHeight: 30,
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5), // Order ID
                  1: const pw.FlexColumnWidth(2.5), // Customer Name
                  2: const pw.FlexColumnWidth(1.5), // Phone 1
                  3: const pw.FlexColumnWidth(1.5), // Phone 2
                  4: const pw.FlexColumnWidth(2), // Place
                  5: const pw.FlexColumnWidth(2), // Salesman
                  6: const pw.FlexColumnWidth(2), // Maker
                  7: const pw.FlexColumnWidth(1.5), // Order Status
                  8: const pw.FlexColumnWidth(2), // Created At
                  9: const pw.FlexColumnWidth(2), // Delivery Date
                  10: const pw.FlexColumnWidth(2), // Follow Up Date
                  11: const pw.FlexColumnWidth(1), // NOS
                },
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Total Orders: ${ordersData.length}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                'Generated on: ${dateFormat.format(DateTime.now().toLocal())}',
                style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic,
                  fontSize: 10,
                ),
              ),
            ];
          },
        ),
      );

      final outputDir = await getTemporaryDirectory();
      final fileName =
          'delivered_orders_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) Navigator.of(context).pop();
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Delivered Orders Report',
        subject:
            'Delivered Orders Report - ${dateFormat.format(DateTime.now().toLocal())}',
      );

      Get.snackbar(
        'PDF Ready for Sharing',
        'PDF report saved to ${file.path.split('/').last}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        mainButton: TextButton(
          onPressed: () => OpenFile.open(file.path),
          child: const Text('Open File', style: TextStyle(color: Colors.white)),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      log('Error sharing orders PDF: $e');
      Get.snackbar(
        'Error',
        'Failed to prepare PDF for sharing: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Shares all "delivered" order data as an Excel file (based on current filters).
  Future<void> shareAllOrdersDataAsExcel(BuildContext context) async {
    if (isLoading.value) return;

    bool hasPermission = await checkStoragePermission();
    if (!hasPermission) return;

    isLoading.value = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text(
              'Preparing Excel for sharing...',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );

    try {
      final ordersData = await _getFilteredOrdersDataForReport();

      if (ordersData.isEmpty) {
        if (context.mounted) Navigator.of(context).pop();
        Get.snackbar(
          'No Data',
          'No orders found to share in Excel based on current filters.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final file = await _generateOrdersExcelFile(ordersData);
      if (context.mounted) Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Delivered Orders Report',
        subject:
            'Delivered Orders Report - ${DateFormat('dd-MMM-yyyy HH:mm').format(DateTime.now().toLocal())}',
      );

      Get.snackbar(
        'Excel Ready for Sharing',
        'Excel report saved to ${file.path.split('/').last}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        mainButton: TextButton(
          onPressed: () => OpenFile.open(file.path),
          child: const Text('Open File', style: TextStyle(color: Colors.white)),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      log('Error sharing orders Excel: $e');
      Get.snackbar(
        'Error',
        'Failed to prepare Excel for sharing: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // /// Downloads all "delivered" order data as an Excel file (based on current filters).
  // Future<void> downloadAllOrdersDataAsExcel(BuildContext context) async {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => const AlertDialog(
  //       content: Row(
  //         children: [
  //           CircularProgressIndicator(),
  //           SizedBox(width: 16),
  //           Text('Generating Excel...'),
  //         ],
  //       ),
  //     ),
  //   );

  //   try {
  //     final ordersData =
  //         await _getFilteredOrdersDataForReport(); // Use filtered data

  //     if (ordersData.isEmpty) {
  //       if (context.mounted) Navigator.of(context).pop();
  //       if (context.mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('No orders found to download in Excel.'),
  //             backgroundColor: Colors.orange,
  //           ),
  //         );
  //       }
  //       return;
  //     }

  //     final file = await _generateOrdersExcelFile(ordersData);
  //     if (context.mounted) Navigator.of(context).pop();

  //     if (context.mounted) {
  //       showDialog(
  //         context: context,
  //         builder: (context) => AlertDialog(
  //           title: const Text('Excel Generated'),
  //           content: Text(
  //             'Excel file "${file.path.split('/').last}" has been saved to app documents directory. Would you like to open it?',
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.of(context).pop(),
  //               child: const Text('Cancel'),
  //             ),
  //             TextButton(
  //               onPressed: () async {
  //                 if (context.mounted) Navigator.of(context).pop();
  //                 final result = await OpenFile.open(file.path);
  //                 if (result.type != ResultType.done) {
  //                   if (context.mounted) {
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       SnackBar(
  //                         content: Text(
  //                           'Could not open Excel: ${result.message}',
  //                         ),
  //                         backgroundColor: Colors.red,
  //                       ),
  //                     );
  //                   }
  //                 }
  //               },
  //               child: const Text('Open'),
  //             ),
  //           ],
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (context.mounted) Navigator.of(context).pop();
  //     log('Error generating Excel: $e');
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error generating Excel: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  // /// Shares all "delivered" order data as an Excel file (based on current filters).
  // Future<void> shareAllOrdersDataAsExcel(BuildContext context) async {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => const AlertDialog(
  //       content: Row(
  //         children: [
  //           CircularProgressIndicator(),
  //           SizedBox(width: 16),
  //           Text('Preparing Excel for sharing...'),
  //         ],
  //       ),
  //     ),
  //   );

  //   try {
  //     final ordersData =
  //         await _getFilteredOrdersDataForReport(); // Use filtered data

  //     if (ordersData.isEmpty) {
  //       if (context.mounted) Navigator.of(context).pop();
  //       if (context.mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('No orders found to share.'),
  //             backgroundColor: Colors.orange,
  //           ),
  //         );
  //       }
  //       return;
  //     }

  //     final file = await _generateOrdersExcelFile(ordersData);
  //     if (context.mounted) Navigator.of(context).pop();

  //     await Share.shareXFiles(
  //       [XFile(file.path)],
  //       text: 'All Orders Data Report',
  //       subject:
  //           'Orders Data Export - ${DateTime.now().toLocal().toString().split(' ')[0]}',
  //     );

  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Excel file prepared for sharing'),
  //           backgroundColor: Colors.green,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (context.mounted) Navigator.of(context).pop();
  //     log('Error sharing Excel: $e');
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error sharing Excel: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }
}
