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

// Controller
class LeadReportController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable variables
  final RxList<Map<String, dynamic>> allLeads = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredLeads =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> paginatedLeads =
      <Map<String, dynamic>>[].obs;

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

  // Filter options
  final RxList<String> availablePlaces = <String>[].obs;
  final RxList<String> availableSalespeople = <String>[].obs;
  TextEditingController searchController = TextEditingController();

  // Pagination and lazy loading variables
  final int itemsPerPage = 15;
  DocumentSnapshot? _lastDocument;
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    fetchLeads();
    fetchAllSalespeople();

    // Listen to search query changes with debounce
    debounce(
      searchQuery,
      (_) => filterLeads(),
      time: const Duration(milliseconds: 500),
    );

    // Add scroll listener for infinite scrolling
    scrollController.addListener(_scrollListener);
  }

  @override
  void onClose() {
    scrollController.dispose();
    searchController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore.value &&
        hasMoreData.value) {
      fetchMoreLeads();
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

  void extractAvailableSalespeople() {
    final Set<String> salespeople = {};

    for (var lead in allLeads) {
      final salesperson = lead['salesman']
          ?.toString()
          .trim(); // <-- Match your Firestore key exactly!
      if (salesperson != null && salesperson.isNotEmpty) {
        salespeople.add(salesperson);
      }
    }

    availableSalespeople.assignAll(salespeople.toList());
  }

  Future<void> fetchLeads({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        _lastDocument = null;
        allLeads.clear();
        hasMoreData.value = true;
      }

      isLoading.value = true;
      Query<Map<String, dynamic>> query = _firestore
          .collection('Leads')
          .orderBy('createdAt', descending: true)
          .limit(itemsPerPage);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot<Map<String, dynamic>> leadSnapshot = await query.get();

      if (leadSnapshot.docs.isEmpty) {
        hasMoreData.value = false;
        return;
      }

      List<Map<String, dynamic>> tempLeads = [];
      Set<String> placesSet = {};
      Set<String> salespeopleSet = {};
      Set<String> salesmanIDs = {};

      // 1. Collect all salesmanIDs
      for (var doc in leadSnapshot.docs) {
        final salesmanID = doc.data()['salesmanID'];
        if (salesmanID != null && salesmanID.toString().isNotEmpty) {
          salesmanIDs.add(salesmanID.toString());
        }
      }

      // 2. Fetch all salesman names in batch
      Map<String, String> salesmanIdToName = {};
      if (salesmanIDs.isNotEmpty) {
        final userDocs = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: salesmanIDs.toList())
            .get();

        for (var userDoc in userDocs.docs) {
          final name = userDoc.data()['name'] ?? 'Unknown';
          salesmanIdToName[userDoc.id] = name;
        }
      }

      // 3. Process leads
      for (var doc in leadSnapshot.docs) {
        final data = doc.data();
        final salesmanID = data['salesmanID'];
        final salesmanName = salesmanIdToName[salesmanID] ?? 'Unknown';

        tempLeads.add({
          'address': data['address'] ?? '',
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'followUpDate':
              (data['followUpDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'isArchived': data['isArchived'] ?? false,
          'leadId': data['leadId'] ?? '',
          'name': data['name'] ?? '',
          'nos': data['nos'] ?? '',
          'phone1': data['phone1'] ?? '',
          'phone2': data['phone2'] ?? '',
          'place': data['place'] ?? '',
          'productID': data['productID'] ?? '',
          'remark': data['remark'] ?? '',
          'salesman': salesmanName,
          'status': data['status'] ?? '',
          'customerId': data['customerId'],
        });

        final place = data['place']?.toString().trim();
        if (place != null && place.isNotEmpty) {
          placesSet.add(place);
        }

        // if (salesmanName.isNotEmpty && salesmanName != 'N/A') {
        //   salespeopleSet.add(salesmanName);
        // }
        if (salesmanName.isNotEmpty &&
            salesmanName != 'N/A' &&
            salesmanName != 'Unknown' &&
            salesmanName != 'Not Found' &&
            salesmanName != 'Error') {
          salespeopleSet.add(salesmanName);
        }
      }

      _lastDocument = leadSnapshot.docs.last;
      allLeads.addAll(tempLeads);

      availablePlaces.value = placesSet.toList()..sort();

      filterLeads();
      isDataLoaded.value = true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch leads: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMoreLeads() async {
    if (!hasMoreData.value || isLoadingMore.value) return;

    try {
      isLoadingMore.value = true;
      await fetchLeads();
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> filterLeads() async {
    try {
      isLoading.value = true;
      allLeads.clear(); // Optional: Only if you want to reset results
      Query<Map<String, dynamic>> query = _firestore.collection('Leads');

      // Apply Firestore-supported filters
      if (statusFilter.value.isNotEmpty && statusFilter.value != 'All') {
        query = query.where('status', isEqualTo: statusFilter.value);
      }

      if (placeFilter.value.isNotEmpty && placeFilter.value != 'All') {
        query = query.where('place', isEqualTo: placeFilter.value);
      }

      if (salespersonFilter.value.isNotEmpty &&
          salespersonFilter.value != 'All') {
        // Note: Only works if `salesmanID` is stored in leads
        final salesmen = await _firestore
            .collection('users')
            .where('name', isEqualTo: salespersonFilter.value)
            .get();

        if (salesmen.docs.isNotEmpty) {
          final id = salesmen.docs.first.id;
          query = query.where('salesmanID', isEqualTo: id);
        } else {
          allLeads.clear();
          filteredLeads.clear();
          return;
        }
      }

      if (startDate.value != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: startDate.value,
        );
      }

      if (endDate.value != null) {
        final inclusiveEnd = endDate.value!.add(const Duration(days: 1));
        query = query.where('createdAt', isLessThan: inclusiveEnd);
      }

      // Run query
      final snapshot = await query.orderBy('createdAt', descending: true).get();

      final List<Map<String, dynamic>> tempLeads = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final salesmanName = await getSalesmanName(data['salesmanID']);

        final lead = {
          'address': data['address'] ?? '',
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'followUpDate': (data['followUpDate'] as Timestamp?)?.toDate(),
          'isArchived': data['isArchived'] ?? false,
          'leadId': data['leadId'] ?? '',
          'name': data['name'] ?? '',
          'nos': data['nos'] ?? '',
          'phone1': data['phone1'] ?? '',
          'phone2': data['phone2'] ?? '',
          'place': data['place'] ?? '',
          'productID': data['productID'] ?? '',
          'remark': data['remark'] ?? '',
          'salesman': salesmanName,
          'status': data['status'] ?? '',
          'customerId': data['customerId'],
        };

        tempLeads.add(lead);
      }

      allLeads.assignAll(tempLeads);

      // Apply client-side search filter (if needed)
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        filteredLeads.value = allLeads.where((lead) {
          return lead['name'].toString().toLowerCase().contains(query) ||
              lead['leadId'].toString().toLowerCase().contains(query) ||
              lead['phone1'].toString().toLowerCase().contains(query) ||
              lead['salesman'].toString().toLowerCase().contains(query) ||
              lead['place'].toString().toLowerCase().contains(query);
        }).toList();
      } else {
        filteredLeads.assignAll(allLeads);
      }

      paginatedLeads.assignAll(filteredLeads);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch filtered leads: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void setLeadSourceFilter(String? value) {
    // leadSourceFilter.value = value ?? '';
  }
  void setStatusFilter(String? status) {
    statusFilter.value = status ?? '';
    filterLeads();
  }

  void setPlaceFilter(String? place) {
    placeFilter.value = place ?? '';
    filterLeads();
  }

  void setSalespersonFilter(String? salesperson) {
    salespersonFilter.value = salesperson ?? '';
    filterLeads();
  }

  void setDateRange(DateTimeRange? range) {
    startDate.value = range?.start;
    endDate.value = range?.end;
    filterLeads();
  }

  void clearFilters() {
    // leadSourceFilter.value = 'All';
    statusFilter.value = '';
    placeFilter.value = '';
    salespersonFilter.value = '';
    startDate.value = null;
    endDate.value = null;
    searchQuery.value = '';
    filterLeads();
  }

  Future<List<Map<String, dynamic>>> _getFilteredLeadsDataForReport() async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('Leads')
          .orderBy('createdAt', descending: true);

      // Apply filters
      if (salespersonFilter.value.isNotEmpty &&
          salespersonFilter.value != 'All') {
        // Fetch user IDs for the selected salesman name
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

      if (statusFilter.value.isNotEmpty && statusFilter.value != 'All') {
        query = query.where('status', isEqualTo: statusFilter.value);
      }

      if (placeFilter.value.isNotEmpty && placeFilter.value != 'All') {
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

      final QuerySnapshot<Map<String, dynamic>> leadSnapshot = await query
          .get();

      List<Map<String, dynamic>> fullLeadsData = [];
      for (var doc in leadSnapshot.docs) {
        final data = doc.data();
        final String? salesmanID = data['salesmanID'];
        final String salesmanName = await getSalesmanName(salesmanID);

        // Apply search query filter on the client side
        final String clientSearchQuery = searchQuery.value.toLowerCase();
        final String name = data['name']?.toString().toLowerCase() ?? '';
        final String leadId = data['leadId']?.toString().toLowerCase() ?? '';
        final String phone1 = data['phone1']?.toString().toLowerCase() ?? '';
        final String phone2 = data['phone2']?.toString().toLowerCase() ?? '';
        final String place = data['place']?.toString().toLowerCase() ?? '';
        final String status = data['status']?.toString().toLowerCase() ?? '';

        if (clientSearchQuery.isNotEmpty &&
            !(name.contains(clientSearchQuery) ||
                leadId.contains(clientSearchQuery) ||
                phone1.contains(clientSearchQuery) ||
                phone2.contains(clientSearchQuery) ||
                place.contains(clientSearchQuery) ||
                salesmanName.toLowerCase().contains(clientSearchQuery) ||
                status.contains(clientSearchQuery))) {
          continue;
        }

        fullLeadsData.add({
          'address': data['address'] ?? '',
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'followUpDate':
              (data['followUpDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'isArchived': data['isArchived'] ?? false,
          'leadId': data['leadId'] ?? '',
          'name': data['name'] ?? '',
          'nos': data['nos'] ?? '',
          'phone1': data['phone1'] ?? '',
          'phone2': data['phone2'] ?? '',
          'place': data['place'] ?? '',
          'productID': data['productID'] ?? '',
          'remark': data['remark'] ?? '',
          'salesman': salesmanName,
          'status': data['status'] ?? '',
          'customerId': data['customerId'] ?? '',
        });
      }
      return fullLeadsData;
    } catch (e) {
      log('Error fetching leads for report: $e');
      Get.snackbar(
        'Error',
        'Failed to retrieve leads for report: $e',
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

  /// Generates an Excel file containing all lead data (based on current filters).
  /// Generates an Excel file containing all lead data (based on current filters).
  Future<File> _generateLeadsExcelFile(
    List<Map<String, dynamic>> leadsData,
  ) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['All Leads Data'];

    // Set column widths
    sheet.setColumnWidth(0, 25); // Lead ID
    sheet.setColumnWidth(1, 25); // Name
    sheet.setColumnWidth(2, 20); // Phone1
    sheet.setColumnWidth(3, 20); // Phone2
    sheet.setColumnWidth(4, 30); // Address
    sheet.setColumnWidth(5, 15); // Place
    sheet.setColumnWidth(6, 20); // Salesman
    sheet.setColumnWidth(7, 15); // Status
    sheet.setColumnWidth(8, 20); // Created At
    sheet.setColumnWidth(9, 20); // Follow Up Date
    sheet.setColumnWidth(10, 40); // Remark
    sheet.setColumnWidth(11, 20); // Product ID
    sheet.setColumnWidth(12, 20); // NOS
    sheet.setColumnWidth(13, 20); // Customer ID

    // Add filter description
    final filterDescription = [
      if (salespersonFilter.value.isNotEmpty &&
          salespersonFilter.value != 'All')
        'Salesperson: ${salespersonFilter.value}',
      if (statusFilter.value.isNotEmpty && statusFilter.value != 'All')
        'Status: ${statusFilter.value}',
      if (placeFilter.value.isNotEmpty && placeFilter.value != 'All')
        'Place: ${placeFilter.value}',
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

    // Define header row
    final headers = [
      'Lead ID',
      'Name',
      'Phone1',
      'Phone2',
      'Address',
      'Place',
      'Salesman',
      'Status',
      'Created At',
      'Follow Up Date',
      'Remark',
      'Product ID',
      'NOS',
      'Customer ID',
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
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

    // Populate data rows
    for (int rowIndex = 0; rowIndex < leadsData.length; rowIndex++) {
      final lead = leadsData[rowIndex];

      final rowData = [
        lead['leadId']?.toString() ?? 'N/A',
        lead['name']?.toString() ?? 'N/A',
        lead['phone1']?.toString() ?? 'N/A',
        lead['phone2']?.toString() ?? 'N/A',
        lead['address']?.toString() ?? 'N/A',
        lead['place']?.toString() ?? 'N/A',
        lead['salesman']?.toString() ?? 'N/A',
        lead['status']?.toString() ?? 'N/A',
        (lead['createdAt'] as DateTime?) != null
            ? dateFormat.format(lead['createdAt'])
            : 'N/A',
        (lead['followUpDate'] as DateTime?) != null
            ? dateFormat.format(lead['followUpDate'])
            : 'N/A',
        lead['remark']?.toString() ?? 'N/A',
        lead['productID']?.toString() ?? 'N/A',
        lead['nos']?.toString() ?? 'N/A',
        lead['customerId']?.toString() ?? 'N/A',
      ];

      for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: colIndex,
            rowIndex: rowIndex + (filterDescription.isNotEmpty ? 2 : 1),
          ),
        );
        cell.value = TextCellValue(rowData[colIndex]);

        if (colIndex == 7) {
          final status = lead['status']?.toString().toLowerCase();
          if (status == 'new') {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString('#BBDEFB'),
            );
          } else if (status == 'contacted') {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString('#E1BEE7'),
            );
          } else if (status == 'qualified') {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString('#C8E6C9'),
            );
          } else if (status == 'unqualified') {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString('#FFCDD2'),
            );
          } else if (status == 'converted') {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString('#B2DFDB'),
            );
          }
        }
      }
    }

    // Add summary row
    final summaryRow =
        leadsData.length + (filterDescription.isNotEmpty ? 3 : 2);
    var summaryCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow),
    );
    summaryCell.value = TextCellValue('Total Leads: ${leadsData.length}');
    summaryCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 12,
      backgroundColorHex: ExcelColor.fromHexString('#E0E0E0'),
    );

    // Add timestamp
    final timestampRow = summaryRow + 1;
    var timestampCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: timestampRow),
    );
    timestampCell.value = TextCellValue(
      'Generated on: ${dateFormat.format(DateTime.now().toLocal())}',
    );
    timestampCell.cellStyle = CellStyle(italic: true, fontSize: 10);

    final outputDir = await getTemporaryDirectory();
    final file = File(
      '${outputDir.path}/lead_report_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );

    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    } else {
      throw Exception('Failed to encode Excel file.');
    }

    return file;
  }

  /// Downloads data for a single salesman as a PDF
  Future<void> downloadSingleSalesmanAsPDF(
    BuildContext context,
    String salesmanName,
  ) async {
    if (isExporting.value) return;

    salespersonFilter.value = salesmanName; // Set the filter for the salesman
    await downloadAllLeadsDataAsPDF(context);
    salespersonFilter.value = ''; // Reset the filter after download
  }

  /// Downloads data for a single salesman as an Excel file
  Future<void> downloadSingleSalesmanAsExcel(
    BuildContext context,
    String salesmanName,
  ) async {
    if (isExporting.value) return;

    salespersonFilter.value = salesmanName; // Set the filter for the salesman
    await downloadAllLeadsDataAsExcel(context);
    salespersonFilter.value = ''; // Reset the filter after download
  }

  /// Downloads all lead data as a PDF document (based on current filters).
  /// Downloads all lead data as a PDF document (based on current filters).
  Future<void> downloadAllLeadsDataAsPDF(BuildContext context) async {
    if (isExporting.value) return;

    bool hasPermission = await checkStoragePermission();
    if (!hasPermission) {
      log('Storage permission denied. Cannot download PDF.');
      return;
    }

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
      final leadsData = await _getFilteredLeadsDataForReport();

      if (leadsData.isEmpty) {
        if (context.mounted) Navigator.of(context).pop();
        Get.snackbar(
          'No Data',
          'No leads found to download in PDF based on current filters.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final pdf = pw.Document();
      final dateFormat = DateFormat('dd-MMM-yyyy HH:mm');

      // Build filter description
      final filterDescription = [
        if (salespersonFilter.value.isNotEmpty &&
            salespersonFilter.value != 'All')
          'Salesperson: ${salespersonFilter.value}',
        if (statusFilter.value.isNotEmpty && statusFilter.value != 'All')
          'Status: ${statusFilter.value}',
        if (placeFilter.value.isNotEmpty && placeFilter.value != 'All')
          'Place: ${placeFilter.value}',
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
                  'Lead Report',
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
                  'Lead ID',
                  'Name',
                  'Phone1',
                  'Phone2',
                  'Place',
                  'Salesman',
                  'Status',
                  'Created At',
                ],
                data: leadsData.map((lead) {
                  return [
                    lead['leadId']?.toString() ?? 'N/A',
                    lead['name']?.toString() ?? 'N/A',
                    lead['phone1']?.toString() ?? 'N/A',
                    lead['phone2']?.toString() ?? 'N/A',
                    lead['place']?.toString() ?? 'N/A',
                    lead['salesman']?.toString() ?? 'N/A',
                    lead['status']?.toString() ?? 'N/A',
                    (lead['createdAt'] as DateTime?) != null
                        ? dateFormat.format(lead['createdAt'])
                        : 'N/A',
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
                  6: const pw.FlexColumnWidth(1.2),
                  7: const pw.FlexColumnWidth(2),
                },
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Total Leads: ${leadsData.length}',
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
          'lead_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
          onPressed: () {
            OpenFile.open(file.path);
          },
          child: const Text('Open File', style: TextStyle(color: Colors.white)),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      log('Error downloading leads PDF: $e');
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

  /// Shares all lead data as a PDF file (based on current filters).
  Future<void> shareAllLeadsDataAsPDF(BuildContext context) async {
    if (isExporting.value) return;

    bool hasPermission = await checkStoragePermission();
    if (!hasPermission) {
      log('Storage permission denied. Cannot share PDF.');
      return;
    }

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
      final leadsData = await _getFilteredLeadsDataForReport();

      if (leadsData.isEmpty) {
        if (context.mounted) Navigator.of(context).pop();
        Get.snackbar(
          'No Data',
          'No leads found to share based on current filters.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final pdf = pw.Document();
      final dateFormat = DateFormat('dd-MMM-yyyy HH:mm');

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
                  'Lead Report',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  'Lead ID',
                  'Name',
                  'Phone1',
                  'Phone2',
                  'Place',
                  'Salesman',
                  'Status',
                  'Created At',
                ],
                data: leadsData.map((lead) {
                  return [
                    lead['leadId']?.toString() ?? 'N/A',
                    lead['name']?.toString() ?? 'N/A',
                    lead['phone1']?.toString() ?? 'N/A',
                    lead['phone2']?.toString() ?? 'N/A',
                    lead['place']?.toString() ?? 'N/A',
                    lead['salesman']?.toString() ?? 'N/A',
                    lead['status']?.toString() ?? 'N/A',
                    (lead['createdAt'] as DateTime?) != null
                        ? dateFormat.format(lead['createdAt'])
                        : 'N/A',
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
                cellHeight: 30, // Fixed height for cells to ensure readability
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5), // Lead ID
                  1: const pw.FlexColumnWidth(2.5), // Name
                  2: const pw.FlexColumnWidth(1.5), // Phone1
                  3: const pw.FlexColumnWidth(1.5), // Phone2
                  4: const pw.FlexColumnWidth(2), // Place
                  5: const pw.FlexColumnWidth(2), // Salesman
                  6: const pw.FlexColumnWidth(1.2), // Status
                  7: const pw.FlexColumnWidth(2), // Created At
                },
                // Enable text wrapping for long content
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Total Leads: ${leadsData.length}',
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
          'lead_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Lead Data Report',
        subject:
            'Lead Data Export - ${DateFormat('dd-MMM-yyyy').format(DateTime.now().toLocal())}',
      );

      Get.snackbar(
        'Share Initiated',
        'PDF file prepared for sharing.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      log('Error sharing PDF: $e');
      Get.snackbar(
        'Error',
        'Failed to share PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isExporting.value = false;
    }
  }

  /// Downloads all lead data as an Excel file (based on current filters).
  Future<void> downloadAllLeadsDataAsExcel(BuildContext context) async {
    if (isExporting.value) return;

    bool hasPermission = await checkStoragePermission();
    if (!hasPermission) {
      log('Storage permission denied. Cannot download Excel.');
      return;
    }

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
      final leadsData = await _getFilteredLeadsDataForReport();

      if (leadsData.isEmpty) {
        if (context.mounted) Navigator.of(context).pop();
        Get.snackbar(
          'No Data',
          'No leads found to download in Excel based on current filters.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final file = await _generateLeadsExcelFile(leadsData);
      if (context.mounted) Navigator.of(context).pop();

      Get.snackbar(
        'Excel Generated',
        'Excel file saved to ${file.path.split('/').last}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        mainButton: TextButton(
          onPressed: () {
            OpenFile.open(file.path);
          },
          child: const Text('Open File', style: TextStyle(color: Colors.white)),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      log('Error generating Excel: $e');
      Get.snackbar(
        'Error',
        'Failed to generate Excel: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isExporting.value = false;
    }
  }

  /// Shares all lead data as an Excel file (based on current filters).
  Future<void> shareAllLeadsDataAsExcel(BuildContext context) async {
    if (isExporting.value) return;

    bool hasPermission = await checkStoragePermission();
    if (!hasPermission) {
      log('Storage permission denied. Cannot share Excel.');
      return;
    }

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
              'Preparing Excel for sharing...',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );

    try {
      final leadsData = await _getFilteredLeadsDataForReport();

      if (leadsData.isEmpty) {
        if (context.mounted) Navigator.of(context).pop();
        Get.snackbar(
          'No Data',
          'No leads found to share based on current filters.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final file = await _generateLeadsExcelFile(leadsData);
      if (context.mounted) Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Lead Data Report',
        subject:
            'Lead Data Export - ${DateFormat('dd-MMM-yyyy').format(DateTime.now().toLocal())}',
      );

      // Get.snackbar(
      //   'Share Initiated',
      //   'Excel file prepared for sharing.',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.green,
      //   colorText: Colors.white,
      // );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      log('Error sharing Excel: $e');
      Get.snackbar(
        'Error',
        'Failed to share Excel: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isExporting.value = false;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'HOT':
        return Colors.red.shade100;
      case 'WARM':
        return Colors.orange.shade100;
      case 'COOL':
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color getStatusTextColor(String status) {
    switch (status.toUpperCase()) {
      case 'HOT':
        return Colors.red.shade800;
      case 'WARM':
        return Colors.orange.shade800;
      case 'COOL':
        return Colors.blue.shade800;
      default:
        return Colors.grey.shade800;
    }
  }
}
