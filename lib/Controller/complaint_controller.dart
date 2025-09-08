import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ComplaintController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reactive filter variables
  var selectedStatus = 'All'.obs;
  var selectedPriority = 'All'.obs;
  var selectedCategory = 'All'.obs;
  var selectedRole = 'All'.obs;
  var searchQuery = ''.obs;

  final List<String> statusOptions = [
    'All',
    'pending',
    'in-progress',
    'resolved',
  ];

  final List<String> priorityOptions = ['All', '1', '2', '3'];

  final List<String> categoryOptions = [
    'All',
    'General',
    'Technical Issue',
    'Staff Behavior',
  ];

  final List<String> roleOptions = ['All', 'salesmen', 'maker'];

  @override
  void onInit() {
    super.onInit();
    // Debug print to check if controller is initialized
    debugPrint("ComplaintController initialized");
  }

  // Method to clear all filters
  void clearFilters() {
    selectedStatus.value = 'All';
    selectedPriority.value = 'All';
    selectedCategory.value = 'All';
    selectedRole.value = 'All';
    searchQuery.value = '';
    debugPrint("All filters cleared");
  }

  Stream<QuerySnapshot> getFilteredComplaints() {
    debugPrint("=== FILTER DEBUG ===");
    debugPrint("Status filter: ${selectedStatus.value}");
    debugPrint("Priority filter: ${selectedPriority.value}");
    debugPrint("Category filter: ${selectedCategory.value}");
    debugPrint("Role filter: ${selectedRole.value}");
    debugPrint("Search query: '${searchQuery.value}'");

    try {
      Query query = _firestore
          .collection('complaints')
          .orderBy('timestamp', descending: true);

      // Apply status filter
      if (selectedStatus.value != 'All') {
        query = query.where('status', isEqualTo: selectedStatus.value);
        debugPrint("Applied status filter: ${selectedStatus.value}");
      }

      // Apply priority filter
      if (selectedPriority.value != 'All') {
        int priorityValue = int.parse(selectedPriority.value);
        query = query.where('priority', isEqualTo: priorityValue);
        debugPrint("Applied priority filter: $priorityValue");
      }

      // Apply category filter
      if (selectedCategory.value != 'All') {
        query = query.where('category', isEqualTo: selectedCategory.value);
        debugPrint("Applied category filter: ${selectedCategory.value}");
      }

      debugPrint("=== END FILTER DEBUG ===");
      return query.snapshots();
    } catch (e) {
      debugPrint("Error in getFilteredComplaints: $e");
      // Return empty stream or handle error appropriately
      return const Stream.empty();
    }
  }

  Future<String> getUserRoleByUid(String uid) async {
    debugPrint("START: Fetching user role for userId: $uid");

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final role = userDoc.data()?['role'] ?? 'Unknown';
        debugPrint("Fetched role for $uid: $role");
        return role;
      } else {
        debugPrint("User document not found for UID: $uid");
        return 'Unknown';
      }
    } catch (e) {
      debugPrint("Error fetching user role for $uid: $e");
      return 'Unknown';
    }
  }

  Future<List<Map<String, dynamic>>> enrichComplaintsWithUserData(
    List<QueryDocumentSnapshot> docs,
  ) async {
    debugPrint("START: Enriching ${docs.length} complaints with user data");
    List<Map<String, dynamic>> enrichedComplaints = [];

    for (var doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;

        // Debug complaint data
        debugPrint("Processing complaint doc ID: ${doc.id}");
        debugPrint("Complaint data keys: ${data.keys.toList()}");

        final userId = data['userId'];
        if (userId != null && userId.toString().isNotEmpty) {
          data['userRole'] = await getUserRoleByUid(userId.toString());
        } else {
          data['userRole'] = 'Unknown';
          debugPrint("No userId found in complaint ${doc.id}");
        }

        enrichedComplaints.add(data);
      } catch (e) {
        debugPrint("Error processing complaint ${doc.id}: $e");
        // Still add the complaint with unknown role
        final data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        data['userRole'] = 'Unknown';
        enrichedComplaints.add(data);
      }
    }

    debugPrint("END: Enriched ${enrichedComplaints.length} complaints");
    return enrichedComplaints;
  }

  List<Map<String, dynamic>> applyTextSearch(
    List<Map<String, dynamic>> complaints,
  ) {
    debugPrint("=== TEXT SEARCH DEBUG ===");
    debugPrint("Search query: '${searchQuery.value}'");
    debugPrint("Role filter: '${selectedRole.value}'");
    debugPrint("Input complaints count: ${complaints.length}");

    if (searchQuery.value.isEmpty && selectedRole.value == 'All') {
      debugPrint("No text filters applied, returning all complaints");
      return complaints;
    }

    final filtered = complaints.where((complaint) {
      bool matchesSearch = true;
      bool matchesRole = true;

      // Apply text search
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        matchesSearch =
            (complaint['name']?.toString().toLowerCase().contains(query) ??
                false) ||
            (complaint['email']?.toString().toLowerCase().contains(query) ??
                false) ||
            (complaint['complaint']?.toString().toLowerCase().contains(query) ??
                false) ||
            (complaint['category']?.toString().toLowerCase().contains(query) ??
                false);

        if (matchesSearch) {
          debugPrint("Search match found for complaint ${complaint['docId']}");
        }
      }

      // Apply role filter
      if (selectedRole.value != 'All') {
        final complaintRole =
            complaint['userRole']?.toString().toLowerCase() ?? '';
        final filterRole = selectedRole.value.toLowerCase();
        matchesRole = complaintRole == filterRole;

        if (matchesRole) {
          debugPrint(
            "Role match found for complaint ${complaint['docId']}: $complaintRole",
          );
        }
      }

      final result = matchesSearch && matchesRole;
      if (result) {
        debugPrint("Complaint ${complaint['docId']} passed all filters");
      }

      return result;
    }).toList();

    debugPrint("Filtered complaints count: ${filtered.length}");
    debugPrint("=== END TEXT SEARCH DEBUG ===");

    return filtered;
  }

  // Method to get complaint statistics (optional - for debugging)
  Future<Map<String, int>> getComplaintStats() async {
    try {
      final snapshot = await _firestore.collection('complaints').get();
      final complaints = snapshot.docs;

      Map<String, int> stats = {
        'total': complaints.length,
        'pending': 0,
        'in-progress': 0,
        'resolved': 0,
        'closed': 0,
      };

      for (var doc in complaints) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase() ?? 'pending';
        if (stats.containsKey(status)) {
          stats[status] = stats[status]! + 1;
        }
      }

      debugPrint("Complaint statistics: $stats");
      return stats;
    } catch (e) {
      debugPrint("Error getting complaint stats: $e");
      return {'total': 0};
    }
  }
}
