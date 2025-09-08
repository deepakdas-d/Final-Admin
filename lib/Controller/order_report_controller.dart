import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class OrderReportController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable variables
  final RxList<Map<String, dynamic>> allLeads = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> allOrders = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredOrders =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> paginatedOrders =
      <Map<String, dynamic>>[].obs;
  RxInt totalMatchingOrders = 0.obs;

  final RxString statusFilter = ''.obs;
  final RxString placeFilter = ''.obs;
  final RxString salespersonFilter = ''.obs;
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isDataLoaded = false.obs;
  final RxBool isExporting = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreData = true.obs;

  // Status options
  final List<String> statusOptions = [
    'pending',
    'accepted',
    'sent out for delivery',
    'delivered',
  ];

  // Filter options
  final RxList<String> availablePlaces = <String>[].obs;
  final RxList<String> availableSalespeople = <String>[].obs;

  // Pagination and lazy loading variables
  final int itemsPerPage = 30;
  DocumentSnapshot? _lastDocument;
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    fetchAllSalespeople();
    fetchOrders();
    debounce(
      searchQuery,
      (_) => filterOrders(),
      time: const Duration(milliseconds: 500),
    );
    scrollController.addListener(_scrollListener);
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore.value &&
        hasMoreData.value) {
      fetchMoreOrders();
    }
  }

  Future<String> getSalesmanName(String? uid) async {
    if (uid == null || uid.isEmpty) return 'N/A';
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists
          ? (doc.data() != null
                ? doc.data()!['name'] ?? 'Unknown'
                : 'Not Found')
          : 'Not Found';
    } catch (e) {
      log('Error fetching user for $uid: $e');
      return 'Error';
    }
  }

  Future<String> getMakerName(String? uid) async {
    if (uid == null || uid.isEmpty) return 'N/A';
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists
          ? (doc.data() != null
                ? doc.data()!['name'] ?? 'Unknown'
                : 'Not Found')
          : 'Not Found';
    } catch (e) {
      log('Error fetching maker for $uid: $e');
      return 'Error';
    }
  }

  Future<void> fetchAllSalespeople() async {
    try {
      final userSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'salesmen') // <-- FIXED here
          .get();

      final Set<String> salespeople = userSnapshot.docs
          .map((doc) => doc.data()['name']?.toString().trim() ?? '')
          .where(
            (name) =>
                name.isNotEmpty &&
                name != 'N/A' &&
                name != 'Unknown' &&
                name != 'Not Found' &&
                name != 'Error',
          )
          .toSet();

      availableSalespeople.assignAll(salespeople.toList()..sort());
    } catch (e) {
      log('Error fetching salespeople: $e');
    }
  }

  // void extractAvailableSalespeople() {
  //   final Set<String> salespeople = {};

  //   for (var lead in allLeads) {
  //     final salesperson = lead['salesman']
  //         ?.toString()
  //         .trim(); // <-- Match your Firestore key exactly!
  //     if (salesperson != null && salesperson.isNotEmpty) {
  //       salespeople.add(salesperson);
  //     }
  //   }

  //   availableSalespeople.assignAll(salespeople.toList());
  // }

  Future<void> fetchOrders({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        _lastDocument = null;
        allOrders.clear();
        hasMoreData.value = true;
      }

      isLoading.value = true;
      Query<Map<String, dynamic>> query = _firestore
          .collection('Orders')
          .orderBy('createdAt', descending: true)
          .limit(itemsPerPage);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot<Map<String, dynamic>> orderSnapshot = await query.get();

      if (orderSnapshot.docs.isEmpty) {
        hasMoreData.value = false;
        isLoading.value = false;
        return;
      }

      List<Map<String, dynamic>> tempOrders = [];
      Set<String> placesSet = <String>{};
      // ignore: unused_local_variable
      Set<String> salespeopleSet = <String>{};

      for (var doc in orderSnapshot.docs) {
        final data = doc.data();
        final String? salesmanID = data['salesmanID'];
        final String salesmanName = await getSalesmanName(salesmanID);
        final String? makerID = data['makerId'];
        final String maker = await getMakerName(makerID);

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
          'status': data['status'] ?? '',
          'followUpNotes': data['followUpNotes'] ?? '',
          'maker': maker,
          'Cancel': data['Cancel'] ?? false,
          'customerId': data['customerId'] ?? '',
          'isEdited': data['isEdited'] ?? false,
          'dateChangeCount': data['dateChangeCount'] ?? 0 ?? '',
        });

        final place = data['place']?.toString().trim();
        if (place != null && place.isNotEmpty) placesSet.add(place);
        // if (salesmanName.isNotEmpty && salesmanName != 'N/A')
        //   salespeopleSet.add(salesmanName);
      }

      _lastDocument = orderSnapshot.docs.last;
      allOrders.addAll(tempOrders);
      availablePlaces.value = placesSet.toList()..sort();
      // availableSalespeople.value = salespeopleSet.toList()..sort();
      filterOrders();
      isDataLoaded.value = true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch orders: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMoreOrders() async {
    if (!hasMoreData.value || isLoadingMore.value) return;
    try {
      isLoadingMore.value = true;
      await fetchOrders();
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> fetchTotalFilteredOrderCount() async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('Orders');

      if (statusFilter.value.isNotEmpty) {
        query = query.where('order_status', isEqualTo: statusFilter.value);
      }

      if (placeFilter.value.isNotEmpty) {
        query = query.where('place', isEqualTo: placeFilter.value);
      }

      // 🔄 Fix for salesperson filter
      if (salespersonFilter.value.isNotEmpty &&
          salespersonFilter.value != 'All') {
        // Find user with matching name
        final userSnap = await _firestore
            .collection('users')
            .where('name', isEqualTo: salespersonFilter.value)
            .limit(1)
            .get();

        if (userSnap.docs.isNotEmpty) {
          final salesmanId = userSnap.docs.first.id;
          query = query.where('salesmanID', isEqualTo: salesmanId);
        } else {
          // If no such user found, no documents will match
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

      // 🧮 Firestore count
      final countSnapshot = await query.count().get();
      totalMatchingOrders.value = countSnapshot.count ?? 0;
    } catch (e) {
      print('Error fetching total order count: $e');
      totalMatchingOrders.value = 0;
    }
  }

  void filterOrders() {
    List<Map<String, dynamic>> filtered = allOrders.where((order) {
      bool matches = true;

      if (statusFilter.value.isNotEmpty) {
        matches = matches && order['order_status'] == statusFilter.value;
      }

      if (placeFilter.value.isNotEmpty) {
        matches = matches && order['place'] == placeFilter.value;
      }

      if (salespersonFilter.value.isNotEmpty) {
        matches = matches && order['salesman'] == salespersonFilter.value;
      }

      if (startDate.value != null) {
        matches = matches && order['createdAt'].isAfter(startDate.value!);
      }

      if (endDate.value != null) {
        matches =
            matches &&
            order['createdAt'].isBefore(
              endDate.value!.add(const Duration(days: 1)),
            );
      }

      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        matches =
            matches &&
            (order['name'].toString().toLowerCase().contains(query) ||
                order['orderId'].toString().toLowerCase().contains(query) ||
                order['phone1'].toString().toLowerCase().contains(query) ||
                order['phone2'].toString().toLowerCase().contains(query) ||
                order['salesman'].toString().toLowerCase().contains(query) ||
                order['place'].toString().toLowerCase().contains(query) ||
                order['order_status'].toString().toLowerCase().contains(query));
      }

      return matches;
    }).toList();

    filteredOrders.value = filtered;
    paginatedOrders.value = filtered;

    fetchTotalFilteredOrderCount();
  }

  void setStatusFilter(String? status) {
    statusFilter.value = status ?? '';
    filterOrders();
  }

  void setPlaceFilter(String? place) {
    placeFilter.value = place ?? '';
    filterOrders();
  }

  void setSalespersonFilter(String? salesperson) {
    salespersonFilter.value = salesperson ?? '';
    filterOrders();
  }

  void setDateRange(DateTimeRange? range) {
    startDate.value = range?.start;
    endDate.value = range?.end;
    filterOrders();
  }

  void clearFilters() {
    statusFilter.value = '';
    placeFilter.value = '';
    salespersonFilter.value = '';
    startDate.value = null;
    endDate.value = null;
    searchQuery.value = '';
    filterOrders();
  }

  Future<bool> checkStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    final status = sdkInt >= 30
        ? await Permission.manageExternalStorage.request()
        : await Permission.storage.request();

    if (status.isGranted) return true;

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

  Future<List<Map<String, dynamic>>> _getFilteredOrdersDataForReport() async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('Orders')
          .orderBy('createdAt', descending: true);

      if (salespersonFilter.value.isNotEmpty) {
        final userSnapshot = await _firestore
            .collection('users')
            .where('name', isEqualTo: salespersonFilter.value)
            .get();
        if (userSnapshot.docs.isNotEmpty) {
          final userId = userSnapshot.docs.first.id;
          query = query.where('salesmanID', isEqualTo: userId);
        } else {
          return [];
        }
      }

      if (statusFilter.value.isNotEmpty) {
        query = query.where('order_status', isEqualTo: statusFilter.value);
      }

      if (placeFilter.value.isNotEmpty) {
        query = query.where('place', isEqualTo: placeFilter.value);
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
        final String maker = await getMakerName(makerID);

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
          'status': data['status'] ?? '',
          'followUpNotes': data['followUpNotes'] ?? '',
          'maker': maker,
          'Cancel': data['Cancel'] ?? false,
          'customerId': data['customerId'] ?? '',
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

  Future<void> downloadAllOrdersDataAsPDF(BuildContext context) async {
    if (isExporting.value) return;

    bool hasPermission = await checkStoragePermission();
    if (!hasPermission) return;

    isExporting.value = true;
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

      final filterDescription = [
        if (salespersonFilter.value.isNotEmpty)
          'Salesperson: ${salespersonFilter.value}',
        if (statusFilter.value.isNotEmpty) 'Status: ${statusFilter.value}',
        if (placeFilter.value.isNotEmpty) 'Place: ${placeFilter.value}',
        if (startDate.value != null && endDate.value != null)
          'Date Range: ${dateFormat.format(startDate.value!)} to ${dateFormat.format(endDate.value!)}',
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
                  'Order Report',
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
                  'Name',
                  'Phone1',
                  'Phone2',
                  'Place',
                  'Salesman',
                  'Maker',
                  'Order Status',
                  'Created At',
                  'Delivery Date',
                  'Nos',
                  'Cancel',
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
                    order['nos']?.toString() ?? 'N/A',
                    order['Cancel'] == true ? 'Yes' : 'No',
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
                  0: const pw.FlexColumnWidth(1.5),
                  1: const pw.FlexColumnWidth(2.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(2),
                  5: const pw.FlexColumnWidth(2),
                  6: const pw.FlexColumnWidth(2),
                  7: const pw.FlexColumnWidth(1.5),
                  8: const pw.FlexColumnWidth(2),
                  9: const pw.FlexColumnWidth(2),
                  10: const pw.FlexColumnWidth(1),
                  11: const pw.FlexColumnWidth(1),
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
          'order_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
      isExporting.value = false;
    }
  }

  Future<void> downloadAllOrdersDataAsExcel(BuildContext context) async {
    if (isExporting.value) return;

    bool hasPermission = await checkStoragePermission();
    if (!hasPermission) return;

    isExporting.value = true;
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

      final excel = Excel.createExcel();
      final Sheet sheet = excel['Orders'];

      final filterDescription = [
        if (salespersonFilter.value.isNotEmpty)
          'Salesperson: ${salespersonFilter.value}',
        if (statusFilter.value.isNotEmpty) 'Status: ${statusFilter.value}',
        if (placeFilter.value.isNotEmpty) 'Place: ${placeFilter.value}',
        if (startDate.value != null && endDate.value != null)
          'Date Range: ${DateFormat('dd-MMM-yyyy').format(startDate.value!)} to ${DateFormat('dd-MMM-yyyy').format(endDate.value!)}',
      ].join(' | ');

      if (filterDescription.isNotEmpty) {
        var filterCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        );
        filterCell.value = TextCellValue('Filters: $filterDescription');
        filterCell.cellStyle = CellStyle(fontSize: 12, italic: true);
        sheet.setRowHeight(0, 20);
      }

      final headers = [
        'Order ID',
        'Customer Name',
        'Customer ID',
        'Address',
        'Place',
        'Phone1',
        'Phone2',
        'Product ID',
        'Salesman',
        'Maker',
        'Status',
        'Order Status',
        'Created At',
        'Delivery Date',
        'Follow Up Date',
        'Nos',
        'Remark',
        'Follow Up Notes',
        'Cancel',
      ];

      final columnWidths = [
        15.0,
        20.0,
        20.0,
        30.0,
        20.0,
        15.0,
        15.0,
        15.0,
        15.0,
        15.0,
        15.0,
        20.0,
        20.0,
        20.0,
        20.0,
        10.0,
        25.0,
        20.0,
        15.0,
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

      final dateFormat = DateFormat('dd-MMM-yyyy HH:mm');
      for (int rowIndex = 0; rowIndex < ordersData.length; rowIndex++) {
        final order = ordersData[rowIndex];
        final rowData = [
          order['orderId']?.toString() ?? 'N/A',
          order['name']?.toString() ?? 'N/A',
          order['customerId']?.toString() ?? 'N/A',
          order['address']?.toString() ?? 'N/A',
          order['place']?.toString() ?? 'N/A',
          order['phone1']?.toString() ?? 'N/A',
          order['phone2']?.toString() ?? 'N/A',
          order['productID']?.toString() ?? 'N/A',
          order['salesman']?.toString() ?? 'N/A',
          order['maker']?.toString() ?? 'N/A',
          order['status']?.toString() ?? 'N/A',
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
          order['remark']?.toString() ?? 'N/A',
          order['followUpNotes']?.toString() ?? 'N/A',
          order['Cancel'] == true ? 'Yes' : 'No',
        ];

        for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
          var cell = sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: colIndex,
              rowIndex: rowIndex + (filterDescription.isNotEmpty ? 2 : 1),
            ),
          );
          cell.value = TextCellValue(rowData[colIndex]);

          if (colIndex == 11) {
            final orderStatus = order['order_status']?.toString().toLowerCase();
            cell.cellStyle = CellStyle(
              backgroundColorHex: orderStatus == 'delivered'
                  ? ExcelColor.fromHexString('#C8E6C9')
                  : orderStatus == 'accepted'
                  ? ExcelColor.fromHexString('#D4EDDA')
                  : orderStatus == 'inprogress'
                  ? ExcelColor.fromHexString('#FFF3CD')
                  : orderStatus == 'sent out for delivery'
                  ? ExcelColor.fromHexString('#FFE5B4')
                  : orderStatus == 'pending'
                  ? ExcelColor.fromHexString('#F8D7DA')
                  : ExcelColor.fromHexString('#FFFFFF'),
            );
          }

          if (colIndex == 18 && order['Cancel'] == true) {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString('#F8D7DA'),
            );
          }
        }
      }

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

      var timestampCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 1),
      );
      timestampCell.value = TextCellValue(
        'Generated on: ${dateFormat.format(DateTime.now().toLocal())}',
      );
      timestampCell.cellStyle = CellStyle(italic: true, fontSize: 10);

      final outputDir = await getTemporaryDirectory();
      final file = File(
        '${outputDir.path}/order_report_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
      } else {
        throw Exception('Failed to encode Excel file.');
      }

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
      isExporting.value = false;
    }
  }

  Future<void> downloadSingleSalesmanAsPDF(
    BuildContext context,
    String salesmanName,
  ) async {
    if (isExporting.value) return;
    salespersonFilter.value = salesmanName;
    await downloadAllOrdersDataAsPDF(context);
    salespersonFilter.value = '';
  }

  Future<void> downloadSingleSalesmanAsExcel(
    BuildContext context,
    String salesmanName,
  ) async {
    if (isExporting.value) return;
    salespersonFilter.value = salesmanName;
    await downloadAllOrdersDataAsExcel(context);
    salespersonFilter.value = '';
  }

  Future<void> shareAllOrdersDataAsPDF(BuildContext context) async {
    if (isExporting.value) return;

    bool hasPermission = await checkStoragePermission();
    if (!hasPermission) return;

    isExporting.value = true;
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

      final filterDescription = [
        if (salespersonFilter.value.isNotEmpty)
          'Salesperson: ${salespersonFilter.value}',
        if (statusFilter.value.isNotEmpty) 'Status: ${statusFilter.value}',
        if (placeFilter.value.isNotEmpty) 'Place: ${placeFilter.value}',
        if (startDate.value != null && endDate.value != null)
          'Date Range: ${dateFormat.format(startDate.value!)} to ${dateFormat.format(endDate.value!)}',
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
                  'Order Report',
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
                  'Name',
                  'Phone1',
                  'Phone2',
                  'Place',
                  'Salesman',
                  'Maker',
                  'Order Status',
                  'Created At',
                  'Delivery Date',
                  'Nos',
                  'Cancel',
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
                    order['nos']?.toString() ?? 'N/A',
                    order['Cancel'] == true ? 'Yes' : 'No',
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
                  0: const pw.FlexColumnWidth(1.5),
                  1: const pw.FlexColumnWidth(2.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(2),
                  5: const pw.FlexColumnWidth(2),
                  6: const pw.FlexColumnWidth(2),
                  7: const pw.FlexColumnWidth(1.5),
                  8: const pw.FlexColumnWidth(2),
                  9: const pw.FlexColumnWidth(2),
                  10: const pw.FlexColumnWidth(1),
                  11: const pw.FlexColumnWidth(1),
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
          'order_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Order Data Report',
        subject:
            'Order Data Export - ${DateFormat('dd-MMM-yyyy').format(DateTime.now().toLocal())}',
      );

      // Get.snackbar(
      //   'PDF Ready for Sharing',
      //   'PDF report saved to ${file.path.split('/').last}',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.green,
      //   colorText: Colors.white,
      //   mainButton: TextButton(
      //     onPressed: () => OpenFile.open(file.path),
      //     child: const Text('Open File', style: TextStyle(color: Colors.white)),
      //   ),
      // );
    } catch (e) {
      log('Error sharing orders PDF: $e');
      Get.snackbar(
        'Error',
        'Failed to prepare PDF for sharing: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> shareAllOrdersDataAsExcel(BuildContext context) async {
    if (isExporting.value) return;

    bool hasPermission = await checkStoragePermission();
    if (!hasPermission) return;

    isExporting.value = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text(
              'Preparing Execl for sharing...',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
    try {
      final ordersData = await _getFilteredOrdersDataForReport();

      if (ordersData.isEmpty) {
        Get.snackbar(
          'No Data',
          'No orders found to share in Excel based on current filters.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final excel = Excel.createExcel();
      final Sheet sheet = excel['Orders'];

      final filterDescription = [
        if (salespersonFilter.value.isNotEmpty)
          'Salesperson: ${salespersonFilter.value}',
        if (statusFilter.value.isNotEmpty) 'Status: ${statusFilter.value}',
        if (placeFilter.value.isNotEmpty) 'Place: ${placeFilter.value}',
        if (startDate.value != null && endDate.value != null)
          'Date Range: ${DateFormat('dd-MMM-yyyy').format(startDate.value!)} to ${DateFormat('dd-MMM-yyyy').format(endDate.value!)}',
      ].join(' | ');

      if (filterDescription.isNotEmpty) {
        var filterCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        );
        filterCell.value = TextCellValue('Filters: $filterDescription');
        filterCell.cellStyle = CellStyle(fontSize: 12, italic: true);
        sheet.setRowHeight(0, 20);
      }

      final headers = [
        'Order ID',
        'Customer Name',
        'Customer ID',
        'Address',
        'Place',
        'Phone1',
        'Phone2',
        'Product ID',
        'Salesman',
        'Maker',
        'Status',
        'Order Status',
        'Created At',
        'Delivery Date',
        'Follow Up Date',
        'Nos',
        'Remark',
        'Follow Up Notes',
        'Cancel',
      ];

      final columnWidths = [
        15.0,
        20.0,
        20.0,
        30.0,
        20.0,
        15.0,
        15.0,
        15.0,
        15.0,
        15.0,
        15.0,
        20.0,
        20.0,
        20.0,
        20.0,
        10.0,
        25.0,
        20.0,
        15.0,
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

      final dateFormat = DateFormat('dd-MMM-yyyy HH:mm');
      for (int rowIndex = 0; rowIndex < ordersData.length; rowIndex++) {
        final order = ordersData[rowIndex];
        final rowData = [
          order['orderId']?.toString() ?? 'N/A',
          order['name']?.toString() ?? 'N/A',
          order['customerId']?.toString() ?? 'N/A',
          order['address']?.toString() ?? 'N/A',
          order['place']?.toString() ?? 'N/A',
          order['phone1']?.toString() ?? 'N/A',
          order['phone2']?.toString() ?? 'N/A',
          order['productID']?.toString() ?? 'N/A',
          order['salesman']?.toString() ?? 'N/A',
          order['maker']?.toString() ?? 'N/A',
          order['status']?.toString() ?? 'N/A',
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
          order['remark']?.toString() ?? 'N/A',
          order['followUpNotes']?.toString() ?? 'N/A',
          order['Cancel'] == true ? 'Yes' : 'No',
        ];

        for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
          var cell = sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: colIndex,
              rowIndex: rowIndex + (filterDescription.isNotEmpty ? 2 : 1),
            ),
          );
          cell.value = TextCellValue(rowData[colIndex]);

          if (colIndex == 11) {
            final orderStatus = order['order_status']?.toString().toLowerCase();
            cell.cellStyle = CellStyle(
              backgroundColorHex: orderStatus == 'delivered'
                  ? ExcelColor.fromHexString('#C8E6C9')
                  : orderStatus == 'accepted'
                  ? ExcelColor.fromHexString('#D4EDDA')
                  : orderStatus == 'inprogress'
                  ? ExcelColor.fromHexString('#FFF3CD')
                  : orderStatus == 'sent out for delivery'
                  ? ExcelColor.fromHexString('#FFE5B4')
                  : orderStatus == 'pending'
                  ? ExcelColor.fromHexString('#F8D7DA')
                  : ExcelColor.fromHexString('#FFFFFF'),
            );
          }

          if (colIndex == 18 && order['Cancel'] == true) {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString('#F8D7DA'),
            );
          }
        }
      }

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

      var timestampCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 1),
      );
      timestampCell.value = TextCellValue(
        'Generated on: ${dateFormat.format(DateTime.now().toLocal())}',
      );
      timestampCell.cellStyle = CellStyle(italic: true, fontSize: 10);

      final outputDir = await getTemporaryDirectory();
      final file = File(
        '${outputDir.path}/order_report_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
      } else {
        throw Exception('Failed to encode Excel file.');
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Order Data Report',
        subject:
            'Oreder Data Export - ${DateFormat('dd-MMM-yyyy').format(DateTime.now().toLocal())}',
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
      log('Error sharing orders Excel: $e');
      Get.snackbar(
        'Error',
        'Failed to prepare Excel for sharing: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isExporting.value = false;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green.shade100;
      case 'accepted':
        return Colors.lightGreen.shade100;
      case 'inprogress':
        return Colors.yellow.shade100;
      case 'sent out for delivery':
        return Colors.orange.shade100;
      case 'pending':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green.shade800;
      case 'accepted':
        return Colors.lightGreen.shade800;
      case 'inprogress':
        return Colors.yellow.shade800;
      case 'sent out for delivery':
        return Colors.orange.shade800;
      case 'pending':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  Color getOrderStatusColor(String orderStatus) {
    switch (orderStatus.toLowerCase()) {
      case 'delivered':
        return Colors.green.shade100;
      case 'accepted':
        return Colors.lightGreen.shade100;
      case 'inprogress':
        return Colors.yellow.shade100;
      case 'sent out for delivery':
        return Colors.orange.shade100;
      case 'pending':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color getOrderStatusTextColor(String orderStatus) {
    switch (orderStatus.toLowerCase()) {
      case 'delivered':
        return Colors.green.shade800;
      case 'accepted':
        return Colors.lightGreen.shade800;
      case 'inprogress':
        return Colors.yellow.shade800;
      case 'sent out for delivery':
        return Colors.orange.shade800;
      case 'pending':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }
}
